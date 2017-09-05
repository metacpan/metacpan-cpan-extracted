package Lemonldap::NG::Common::PSGI;

use 5.10.0;
use Mouse;
use JSON;
use Lemonldap::NG::Common;
use Lemonldap::NG::Common::PSGI::Constants;
use Lemonldap::NG::Common::PSGI::Request;

our $VERSION = '1.9.3';

our $_json = JSON->new->allow_nonref;

has error        => ( is => 'rw', default => '' );
has languages    => ( is => 'rw', isa     => 'Str', default => 'en' );
has logLevel     => ( is => 'rw', isa     => 'Str', default => 'info' );
has portal       => ( is => 'rw', isa     => 'Str' );
has staticPrefix => ( is => 'rw', isa     => 'Str' );
has templateDir  => ( is => 'rw', isa     => 'Str' );
has links        => ( is => 'rw', isa     => 'ArrayRef' );
has menuLinks    => ( is => 'rw', isa     => 'ArrayRef' );
has syslog => (
    is      => 'rw',
    isa     => 'Str',
    trigger => sub {

        if ( $_[0]->{syslog} ) {
            eval {
                require Sys::Syslog;
                Sys::Syslog->import(':standard');
                openlog( 'lemonldap-ng', 'ndelay,pid', $_[0]->{syslog} );
            };
            $_[0]
              ->error("Unable to use syslog with facility $_[0]->{syslog}: $@")
              if ($@);
        }
    },
);

## @method void lmLog(string mess, string level)
# Log subroutine. Print on STDERR messages if it exceeds `logLevel` value
# @param $mess Text to log
# @param $level Level (debug|info|notice|warn|error)
sub lmLog {
    my ( $self, $msg, $level ) = @_;
    my $levels = {
        error  => 4,
        warn   => 3,
        notice => 2,
        info   => 1,
        debug  => 0
    };
    my $l = $levels->{$level} || 1;
    return if ( ref($self) and $l < $levels->{ $self->{logLevel} } );
    print STDERR "[$level] " . ( $l ? '' : (caller)[0] . ': ' ) . " $msg\n";
}

##@method void userLog(string mess, string level)
# Log user actions on Apache logs or syslog.
# @param $mess string to log
# @param $level level of log message
sub userLog {
    my ( $self, $mess, $level ) = @_;
    if ( $self->{syslog} ) {
        $level =~ s/^warn$/warning/;
        syslog( $level || 'notice', $mess );
    }
    else {
        $self->lmLog( $mess, $level );
    }
}

##@method void userInfo(string mess)
# Log non important user actions. Alias for userLog() with facility "info".
# @param $mess string to log
sub userInfo {
    my ( $self, $mess ) = @_;
    $self->userLog( $mess, 'info' );
}

##@method void userNotice(string mess)
# Log user actions like access and logout. Alias for userLog() with facility
# "notice".
# @param $mess string to log
sub userNotice {
    my ( $self, $mess ) = @_;
    $self->userLog( $mess, 'notice' );
}

##@method void userError(string mess)
# Log user errors like "bad password". Alias for userLog() with facility
# "warn".
# @param $mess string to log
sub userError {
    my ( $self, $mess ) = @_;
    $self->userLog( $mess, 'warn' );
}

# Responses methods
sub sendJSONresponse {
    my ( $self, $req, $j, %args ) = @_;
    $args{code} ||= 200;
    $args{headers} ||= [];
    my $type = 'application/json; charset=utf-8';
    if ( ref $j ) {
        eval { $j = $_json->encode($j); };
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
    return (
          $req->accept =~ /json/
        ? $self->sendJSONresponse( $req, { error => $err }, code => $code )
        : [ $code, [ 'Content-Type' => 'text/plain' ], ["Error: $err"] ]
    );
}

sub abort {
    my ( $self, $err ) = @_;
    $self->lmLog( $err, 'error' );
    return sub {
        $self->sendError( Lemonldap::NG::Common::PSGI::Request->new( $_[0] ),
            $err, 500 );
    };
}

sub _mustBeDefined {
    my $name = ( caller(1) )[3];
    $name =~ s/^.*:://;
    my $call = ( caller(1) )[0];
    my $ref = ref( $_[0] ) || $call;
    die "$name() method must be implemented (probably in $ref)";
}

sub init {
    my ( $self, $args ) = @_;
    unless ( ref $args ) {
        $self->error('init argument must be a hashref');
        return 0;
    }
    foreach my $k ( keys %$args ) {
        $self->{$k} = $args->{$k};
    }
    return 1;
}

sub handler { _mustBeDefined(@_) }

sub sendHtml {
    my ( $self, $req, $template ) = @_;
    my $sp = $self->staticPrefix;
    $sp =~ s/\/*$/\//;
    my $sc = $req->scriptname;
    $sc = '.' unless ($sc);
    $sc =~ s#/*$#/#;
    if ( defined $req->params('js') ) {
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
                'Content-Length' => length($s)
            ],
            [$s]
        ];
    }
    my $htpl;
    $template = $self->templateDir . "/$template.tpl";
    return $self->sendError( $req, "Unable to read $template", 500 )
      unless ( -r $template and -f $template );
    eval {
        $self->lmLog( "Starting HTML generation using $template", 'debug' );
        require HTML::Template;
        $htpl = HTML::Template->new(
            filehandle             => IO::File->new($template),
            path                   => $self->templateDir,
            die_on_bad_params      => 1,
            die_on_missing_include => 1,
            cache                  => 0,
        );

        # TODO: replace app
        # TODO: warn if STATICPREFIX does not end with '/'
        $htpl->param(
            STATIC_PREFIX => $sp,
            SCRIPTNAME    => $sc,
            ( $self->can('tplParams') ? ( $self->tplParams ) : () ),
        );
    };
    if ($@) {
        return $self->sendError( $req, "Unable to load template: $@", 500 );
    }
    $self->lmLog(
        'For more performance, store the result of this as static file',
        'debug' );

    # Set headers
    my $hdrs = [ 'Content-Type' => 'text/html' ];
    unless ( $self->logLevel eq 'debug' ) {
        push @$hdrs,
          ETag            => "LMNG-manager-$VERSION",
          'Cache-Control' => 'private, max-age=2592000';
    }
    $self->lmLog( "Sending $template", 'debug' );
    return [ 200, $hdrs, [ $htpl->output() ] ];
}

###############
# Main method #
###############

sub run {
    my ( $self, $args ) = @_;
    unless ( ref $self ) {
        $self = $self->new($args);
        return $self->abort( $self->error ) unless ( $self->init($args) );
    }
    return $self->_run;
}

sub _run {
    my $self = shift;
    return sub {
        $self->handler( Lemonldap::NG::Common::PSGI::Request->new( $_[0] ) );
    };
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
    # Can use syslog for user actions
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

If $self->syslog is configured, store message with it, else called simply lmLog().
$self->syslog must be empty or contain syslog facility

=head3 userError() userNotice() userInfo()

Alias for userLog(level).

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

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2015-2016 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2015-2016 by Clément Oudot, E<lt>clem.oudot@gmail.comE<gt>

=back

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
