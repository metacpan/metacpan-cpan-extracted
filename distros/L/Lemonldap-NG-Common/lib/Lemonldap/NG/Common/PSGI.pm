package Lemonldap::NG::Common::PSGI;

use strict;
use Mouse;
use JSON;
use Lemonldap::NG::Common::PSGI::Constants;
use Lemonldap::NG::Common::PSGI::Request;

our $VERSION = '2.0.15';

our $_json = JSON->new->allow_nonref;

# PROPERTIES

has error        => ( is => 'rw', default => '' );
has languages    => ( is => 'rw', isa     => 'Str', default => 'en' );
has logLevel     => ( is => 'rw', isa     => 'Str', default => 'info' );
has portal       => ( is => 'rw', isa     => 'Str' );
has staticPrefix => ( is => 'rw', isa     => 'Str' );
has instanceName => ( is => 'rw', isa     => 'Str', default => '' );
has customCSS    => ( is => 'rw', isa     => 'Str', default => '' );
has templateDir  => ( is => 'rw', isa     => 'Str|ArrayRef' );
has links        => ( is => 'rw', isa     => 'ArrayRef' );
has menuLinks    => ( is => 'rw', isa     => 'ArrayRef' );
has logger       => ( is => 'rw' );
has userLogger   => ( is => 'rw' );

# INITIALIZATION

sub init {
    my ( $self, $args ) = @_;
    unless ( ref $args ) {
        $self->error('init argument must be a hashref');
        return 0;
    }
    foreach my $k ( keys %$args ) {
        $self->{$k} = $args->{$k} unless ( $k eq 'logger' );
    }
    unless ( ref( $self->logger ) and ref( $self->userLogger ) ) {
        my $logger =
             $args->{logger}
          || $ENV{LLNG_DEFAULTLOGGER}
          || 'Lemonldap::NG::Common::Logger::Std';
        unless ( ref $self->logger ) {
            eval "require $logger";
            die $@ if ($@);
            my $err;
            unless ( $self->{logLevel} =~ /^(?:debug|info|notice|warn|error)$/ )
            {
                $err =
                    'Bad logLevel value \''
                  . $self->{logLevel}
                  . "', switching to 'info'";
                $self->{logLevel} = 'info';
            }
            $self->logger( $logger->new($self) );
            $self->logger->error($err) if $err;
        }
        unless ( ref $self->userLogger ) {
            $logger = $ENV{LLNG_USERLOGGER} || $args->{userLogger} || $logger;
            eval "require $logger";
            die $@ if ($@);
            require Lemonldap::NG::Common::Logger::_Duplicate;
            $self->userLogger(
                Lemonldap::NG::Common::Logger::_Duplicate->new(
                    $self,
                    user   => 1,
                    logger => $logger,
                    dup    => $self->logger
                )
            );
        }
    }
    return 1;
}

# RUNNING METHODS

## @method void lmLog(string mess, string level)
# Log subroutine. Print on STDERR messages if it exceeds `logLevel` value
# @param $mess Text to log
# @param $level Level (debug|info|notice|warn|error)
sub lmLog {
    my ( $self, $msg, $level ) = @_;
    return $self->logger->$level($msg);
}

##@method void userLog(string mess, string level)
# Log user actions on Apache logs or syslog.
# @param $mess string to log
# @param $level level of log message
sub userLog {
    my ( $self, $msg, $level ) = @_;
    return $self->userLogger->$level($msg);
}

##@method void userInfo(string mess)
# Log non important user actions. Alias for userLog() with facility "info".
# @param $mess string to log
sub userInfo {
    my ( $self, $msg ) = @_;
    return $self->userLogger->info($msg);
}

##@method void userNotice(string mess)
# Log user actions like access and logout. Alias for userLog() with facility
# "notice".
# @param $mess string to log
sub userNotice {
    my ( $self, $msg ) = @_;
    return $self->userLogger->notice($msg);
}

##@method void userWarn(string mess)
# Log user errors like "bad password". Alias for userLog() with facility
# "warn".
# @param $mess string to log
sub userWarn {
    my ( $self, $msg ) = @_;
    return $self->userLogger->warn($msg);
}

##@method void userError(string mess)
# Log user errors like "try to change password without token". Alias for
# userLog() with facility "error".
# @param $mess string to log
sub userError {
    my ( $self, $msg ) = @_;
    return $self->userLogger->error($msg);
}

# Responses methods
sub sendJSONresponse {
    my ( $self, $req, $j, %args ) = @_;
    $args{code}    ||= 200;
    $args{headers} ||= [ $req->spliceHdrs ];
    my $type = 'application/json; charset=utf-8';
    if ( ref $j ) {
        eval {
            if ( $args{pretty} ) {

                # This avoids changing the settings of the $_json reference
                $j = to_json(
                    $j,
                    {
                        allow_nonref => 1,
                        pretty       => 1,
                        canonical    => 1
                    }
                );
            }
            else {
                $j = $_json->encode($j);
            }
        };
        return $self->sendError( $req, $@ ) if ($@);
    }
    return [ $args{code}, [ 'Content-Type' => $type, @{ $args{headers} } ],
        [$j] ];
}

sub sendError {
    my ( $self, $req, $err, $code ) = @_;
    $err  ||= $req->error;
    $code ||= 500;
    $self->lmLog( "Error $code: $err", $code > 499 ? 'error' : 'notice' );

    # SOAP responses
    if ( $req->env->{HTTP_SOAPACTION} ) {
        my $s = '<soapenv:Body>
 <soapenv:Fault>
  <Faultcode>soapenv:Client</Faultcode>
  <Faultstring>' . $err . '.</Faultstring>
  <Detail>
   <Key>Fred</Key>
  </Detail>
 </soapenv:Fault>
</soapenv:Body>';
        return [
            $code,
            [
                'Content-Type'   => 'application/xml; charset=utf-8',
                'Content-Length' => length($s),
                $req->spliceHdrs,
            ],
            [$s]
        ];
    }

    # Handle Ajax responses
    elsif ( $req->accept =~ /json/ ) {
        return $self->sendJSONresponse( $req, { error => $err },
            code => $code );
    }

    # Default response: HTML
    else {
        my $title = (
              $code >= 500 ? 'Server error'
            : $code == 403 ? 'Forbidden'
            : $code == 401 ? 'Authentication required'
            : $code == 400 ? 'Bad request'
            :                'Error'
        );

        # TODO: this should probably use a template instead
        my $s = "<html><head><title>$title</title>
<style>
body{background:#000;color:#fff;padding:10px 50px;font-family:sans-serif;}a{text-decoration:none;color:#fff;}h1{text-align:center;}
</style>
</head>
<body>
<h1>$title</h1>
<p>$err</p>
<center><a href=\"https://lemonldap-ng.org\">LemonLDAP::NG</a></center>
</body>
</html>";
        return $self->sendRawHtml( $req, $s, code => $code );
    }
}

sub sendRawHtml {
    my ( $self, $req, $s, %args ) = @_;
    my $code    = $args{code}    || 200;
    my $headers = $args{headers} || [ $req->spliceHdrs ];
    return [
        $code,
        [
            'Content-Type'   => 'text/html; charset=utf-8',
            'Content-Length' => length($s),
            @{$headers},
        ],
        [$s]
    ];
}

sub abort {
    my ( $self, $err ) = @_;
    eval { $self->logger->error($err) };
    return sub {
        $self->sendError( Lemonldap::NG::Common::PSGI::Request->new( $_[0] ),
            $err, 500 );
    };
}

sub _mustBeDefined {
    my $name = ( caller(1) )[3];
    $name =~ s/^.*:://;
    my $call = ( caller(1) )[0];
    my $ref  = ref( $_[0] ) || $call;
    die "$name() method must be implemented (probably in $ref)";
}

sub handler { _mustBeDefined(@_) }

sub sendJs {
    my ( $self, $req ) = @_;
    my $sp = $self->staticPrefix;
    $sp =~ s/\/*$/\//;
    my $sc = $req->script_name // "";

    # Javascript scriptname is assumed by our JS code to end with /
    $sc =~ s#/*$#/#;
    my $s =
        sprintf 'var staticPrefix="%s";'
      . 'var scriptname="%s";'
      . 'var availableLanguages="%s".split(/[,;] */);'
      . 'var portal="%s";', $sp, $sc, $self->languages, $self->portal;
    $s .= $self->javascript($req) if ( $self->can('javascript') );
    return [
        200,
        [
            'Content-Type'   => 'application/javascript',
            'Content-Length' => length($s),
            'Cache-Control'  => 'public,max-age=2592000',
        ],
        [$s]
    ];
}

sub sendHtml {
    my ( $self, $req, $template, %args ) = @_;
    my $sp = $self->staticPrefix;
    $sp =~ s/\/*$/\//;
    my $sc = $req->script_name // "";

    # SCRIPTNAME is assumed by our templates to end with /
    $sc =~ s#/*$#/#;
    $args{code}    ||= 200;
    $args{headers} ||= [ $req->spliceHdrs ];
    my $htpl;
    $template = ( $args{templateDir} // $self->templateDir ) . "/$template.tpl";
    return $self->sendError( $req, "Unable to read $template", 500 )
      unless ( -r $template and -f $template );
    eval {
        $self->logger->debug("Starting HTML generation using $template");
        require HTML::Template;
        $htpl = HTML::Template->new(
            filehandle             => IO::File->new($template),
            path                   => $self->templateDir,
            search_path_on_include => 1,
            die_on_bad_params      => 0,
            die_on_missing_include => 1,
            cache                  => 0,
            global_vars            => 1,
            loop_context_vars      => 1,
        );

        # TODO: replace app
        # TODO: warn if STATICPREFIX does not end with '/'
        $htpl->param(
            STATIC_PREFIX => $sp,
            INSTANCE_NAME => $self->instanceName,
            CUSTOM_CSS    => $self->customCSS,
            SCRIPTNAME    => $sc,
            ( $self->can('tplParams') ? ( $self->tplParams($req) ) : () ),
            (
                $args{params}
                ? %{ $args{params} }
                : ()
            ),
        );
    };
    if ($@) {
        return $self->sendError( $req, "Unable to load template: $@", 500 );
    }

    # Set headers
    my $hdrs = [ 'Content-Type' => 'text/html', @{ $args{headers} } ];
    $self->logger->debug("Sending $template");
    return [ $args{code}, $hdrs, [ $htpl->output() ] ];
}

###############
# Main method #
###############

sub run {
    my ( $self, $args ) = @_;
    $args //= {};
    unless ( ref $self ) {
        $self = $self->new($args);
        return $self->abort( $self->error ) unless ( $self->init($args) );
    }
    return $self->_run;
}

sub _run {
    my $self = shift;
    return sub {
        $self->_logAndHandle(
            Lemonldap::NG::Common::PSGI::Request->new( $_[0] ) );
    };
}

sub _logAndHandle {
    my ( $self, $req ) = @_;

    # register the request object to the logging system
    if ( ref( $self->logger ) and $self->logger->can('setRequestObj') ) {
        $self->logger->setRequestObj($req);
    }
    if ( ref( $self->userLogger ) and $self->userLogger->can('setRequestObj') )
    {
        $self->userLogger->setRequestObj($req);
    }

    # Call the handler
    my $res = $self->handler($req);

    # Clear the logging system before the next request
    if ( ref( $self->logger ) and $self->logger->can('clearRequestObj') ) {
        $self->logger->clearRequestObj($req);
    }
    if ( ref( $self->userLogger )
        and $self->userLogger->can('clearRequestObj') )
    {
        $self->userLogger->clearRequestObj($req);
    }

    return $res;
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Common::PSGI - Base library for PSGI modules of Lemonldap::NG.
Use Lemonldap::NG::Common::PSGI::Router for REST API.

=head1 SYNOPSIS

  package My::PSGI;
  
  use base Lemonldap::NG::Common::PSGI;
  
  sub init {
    my ($self,$args) = @_;
    # Will be called 1 time during startup
  
    # Store debug level
    $self->logLevel('info');
    # It is possible to use syslog for user actions
    $self->syslog('daemon');
  
    # Return a boolean. If false, then error message has to be stored in
    # $self->error
    return 1;
  }
  
  sub handler {
    my ( $self, $req ) = @_;
    # Do something and return a PSGI response
    # NB: $req is a Lemonldap::NG::Common::PSGI::Request object
    
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Body lines' ] ];
  }

This package could then be called as a CGI, using FastCGI,...

  #!/usr/bin/env perl
  
  use My::PSGI;
  use Plack::Handler::FCGI; # or Plack::Handler::CGI

  Plack::Handler::FCGI->new->run( My::PSGI->run() );

=head1 DESCRIPTION

This package provides base class for Lemonldap::NG web interfaces but could be
used regardless.

=head1 METHODS

=head2 Running methods

=head3 run ( $args )

Main method that will manage requests. It can be called using class or already
created object:

=over

=item Class->run($args):

launch new($args), init(), then manage requests (using private _run() method

=item $object->run():

manage directly requests. Initialization must have be done earlier.

=back

=head2 Logging

=head3 lmLog ( $msg, $level)

Print on STDERR messages if level > $self->{logLevel}. Defined log levels are:
debug, info, notice, warn, error.

=head3 userLog ($msg, $level)

Alias for $self->userLogger->$level($msg). Prefer to use this form (required
for Auth/Combination)

=head3 userError() userNotice() userInfo()

Alias for userLog(level). Note that you must use $self->userLogger->$level
instead

=head2 Content sending

Note that $req, the first argument of these functions, is a
L<Lemonldap::NG::Common::PSGI::Request>. See the corresponding documentation.

=head3 sendHtml ( $req, $template )

This method build HTML response using HTML::Template and the template $template.
$template file must be in $self->templateDir directory.
HTML template will receive 5 variables:

=over

=item SCRIPT_NAME: the path to the (F)CGI

=item STATIC_PREFIX: content of $self->staticPrefix

=item AVAILABLE_LANGUAGES: content of $self->languages

=item LINKS: JSON stringification of $self->links

=item VERSION: Lemonldap::NG version

=back

The response is always send with a 200 code.

=head3 sendJSONresponse ( $req, $json, %args )

Stringify $json object and send it to the client. $req is the
Lemonldap::NG::Common::PSGI::Request object; %args can define the HTTP error
code (200 by default) or headers to add.

If client is not json compatible (`Accept` header), response is send in XML.

Examples:

  $self->sendJSONresponse ( $req, { result => 0 }, code => 400 );

  $self->sendJSONresponse ( $req, { result => 1 } );

  $self->sendJSONresponse ( $req, { result => 1 }, headers => [ X => Z ] );

=head3 sendError ( $req, $msg, $code )

Call sendJSONresponse with `{ error => $msg }` and code (default to 500) and
call lmLog() to duplicate error in logs

=head3 abort ( $msg )

When an error is detected during startup (init() sub), you must not call
sendError() but call abort(). Each request received later will receive the
error (abort uses sendError() behind the scene).

=head2 Accessors

=head3 error

String error. Used if init() fails or if sendError is called without argument.

=head3 languages

String containing list of languages (ie "fr, en'). Used by sendHtml().

=head3 logLevel

See lmLog().

=head3 staticPrefix

String indicating the path of static content (js, css,...). Used by sendHtml().

=head3 templateDir

Directory containing template files.

=head3 links

Array of links to display by sendHtml(). Each element has the form:

 { target => 'http://target', title => 'string to display' }

=head3 syslog

Syslog facility. If empty, STDERR will be used for logging

=head1 SEE ALSO

L<http://lemonldap-ng.org/>, L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Handler>,
L<Plack>, L<PSGI>, L<Lemonldap::NG::Common::PSGI::Router>,
L<Lemonldap::NG::Common::PSGI::Request>, L<HTML::Template>,

=head1 AUTHORS

=over

=item LemonLDAP::NG team L<http://lemonldap-ng.org/team>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<https://lemonldap-ng.org/download>

=head1 COPYRIGHT AND LICENSE

See COPYING file for details.

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
