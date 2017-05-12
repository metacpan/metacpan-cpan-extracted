package Haineko::HTTPD;
use feature ':5.10';
use strict;
use warnings;
use Try::Tiny;
use Path::Class;
use Haineko::JSON;
use Haineko::Default;
use Class::Accessor::Lite;
use Haineko::HTTPD::Router;
use Haineko::HTTPD::Request;
use Haineko::HTTPD::Response;

my $rwaccessors = [
    'debug',    # (Integer) $HAINEKO_DEBUG
    'router',   # (Haineko::HTTPD::Router) Routing table
    'request',  # (Haineko::HTTPD::Request) HTTP Request
    'response', # (Haineko::HTTPD::Response) HTTP Response
];
my $roaccessors = [
    'name',     # (String) System name
    'host',     # (String) SERVER_NAME
    'conf',     # (Ref->Hash) Haineko Configuration
    'root',     # (Path::Class::Dir) Root directory
];
my $woaccessors = [];
Class::Accessor::Lite->mk_accessors( @$rwaccessors );
Class::Accessor::Lite->mk_ro_accessors( @$roaccessors );

sub new {
    my $class = shift;
    my $argvs = { @_ };

    my $hainekodir = $argvs->{'root'} || $ENV{'HAINEKO_ROOT'} || '.';
    my $hainekocfg = $argvs->{'conf'} || $ENV{'HAINEKO_CONF'} || q();
    my $milterlibs = [];

    $argvs->{'name'} = 'Haineko';
    $argvs->{'root'} = Path::Class::Dir->new( $hainekodir ) if $hainekodir;
    $argvs->{'conf'} = Haineko::JSON->loadfile( $hainekocfg ) || Haineko::Default->conf;
    $milterlibs = $argvs->{'conf'}->{'smtpd'}->{'milter'}->{'libs'} || [];

    for my $e ( 'mailer', 'access' ) {
        # Override configuration files
        #   mailertable files and access controll files are overridden the file
        #   which defined in etc/haineko.cf: 
        #
        my $f = $argvs->{'conf'}->{'smtpd'}->{ $e } || Haineko::Default->table( $e );
        my $g = undef;

        for my $ee ( keys %$f ) {
            # etc/{sendermt,mailertable,authinfo}, etc/{relayhosts,recipients}
            # Get an absolute path of each table
            #
            $g = $f->{ $ee };
            $g = sprintf( "%s/etc/%s", $hainekodir, $g ) unless $g =~ m|\A[/.]|;

            if( $ENV{'HAINEKO_DEBUG'} ) {
                # When the value of $HAINEKO_DEBUG is 1,
                # etc/{mailertable,authinfo,sendermt,recipients,relayhosts}-debug
                # are used as a configuration files for debugging.
                #
                if( not $g =~ m/[-]debug\z/ ) {
                    $g .= '-debug' if -f -s -r $g.'-debug';
                }
            }
            $argvs->{'conf'}->{'smtpd'}->{ $e }->{ $ee } = $g;
        }
    } # End of for(TABLE FILES)

    if( ref $milterlibs eq 'ARRAY' ) {
        # Load milter lib path
        require Haineko::SMTPD::Milter;
        Haineko::SMTPD::Milter->libs( $milterlibs );
    }

    $argvs->{'router'}   ||= Haineko::HTTPD::Router->new;
    $argvs->{'request'}  ||= Haineko::HTTPD::Request->new;
    $argvs->{'response'} ||= Haineko::HTTPD::Response->new;

    $argvs->{'host'}  = $argvs->{'request'}->env->{'SERVER_NAME'};
    $argvs->{'debug'} = $ENV{'HAINEKO_DEBUG'} ? 1 : 0;

    return bless $argvs, __PACKAGE__;
}

sub start {
    my $class = shift;
    my $nyaaa = sub {
        my $hainekoenv = shift;
        my $htresponse = undef;
        my $requestnya = Haineko::HTTPD::Request->new( $hainekoenv );
        my $contextnya = $class->new( 'request' => $requestnya );

        local *Haineko::HTTPD::context = sub { $contextnya };
        $htresponse = $class->startup( $contextnya );

        return $htresponse->finalize;
    };

    return $nyaaa;
}

sub req {
    my $self = shift;
    return $self->request;
}

sub res {
    my $self = shift;
    return $self->response;
}

sub rdr {
    my $self = shift;
    my $code = shift || 302;
    my $next = shift;

    $self->response->redirect( $next, $code );
    return $self->response;
}

sub err {
    my $self = shift;
    my $code = shift || 404;
    my $mesg = shift;

    unless( $mesg ) {
        # If the second argument is omitted, use "404 Not found" as a JSON.
        require Haineko::SMTPD::Response;
        $mesg = Haineko::SMTPD::Response->r( 'http', 'not-found' )->damn;
    }

    if( ref $mesg eq 'HASH' ) {
        # Respond as a JSON
        require Haineko::SMTPD::Session;
        my $addr = [ split( ',', $self->req->header('X-Forwarded-For') || q() ) ];
        my $sess = Haineko::SMTPD::Session->new( 
                        'referer'    => $self->req->referer // undef,
                        'response'   => [ $mesg ],
                        'remoteaddr' => pop @$addr || $self->req->address // undef,
                        'remoteport' => $self->req->env->{'REMOTE_ADDR'} // undef,
                        'useragent'  => $self->req->user_agent // undef,
                   )->damn;
        $sess->{'queueid'} = undef;
        return $self->response->json( $code, $sess );

    } else {
        # Respond as a text
        $self->response->code( $code );
        $self->response->content_type( 'text/plain' );
        $self->response->content_length( length $mesg );
        $self->response->body( $mesg );
        return $self->response;
    }
}

sub r {
    my $self = shift;
    my $neko = $self->router->routematch( $self->req->env );

    return $self->err unless $neko;

    my $controller = sprintf( "Haineko::%s", $neko->dest->{'controller'} );
    my $ctrlaction = $neko->dest->{'action'};
    my $exceptions = 0;
    my $htcontents = undef;
    my $nekosyslog = undef;

    try {
        require Module::Load;
        Module::Load::load( $controller );

    } catch {
        require Haineko::Log;
        require Haineko::SMTPD::Response;

        $htcontents = Haineko::SMTPD::Response->r( 'http', 'server-error' )->damn;
        $nekosyslog = Haineko::Log->new( 'disabled' => 0 );

        $htcontents->{'message'}->[1] = $_;
        $nekosyslog->w( 'crit', $htcontents );
        pop @{ $htcontents->{'message'} } unless $self->debug;
        $exceptions = 1;
    };

    return $controller->$ctrlaction( $self ) unless $exceptions;
    return $self->err( 500, { 'response' => $htcontents } );
}

1;
__END__
=encoding utf-8

=head1 NAME

Haineko::HTTPD - Something like web application framework

=head1 DESCRIPTION

Haineko::HTTPD is something like web application framework for Haineko. It contain
wrapper methods of Plack::Request and Plack::Response.

=head1 SYNOPSIS

    $ cat haineko.psgi
    use Haineko;
    Haineko->start;

=head1 CLASS METHODS

=head2 C<B<new( I<%argvs> )>>

C<new()> is a constructor of Haineko::HTTPD, is called from C<start()> method.

=head2 B<start>

C<start()> is a constructor of Haineko::HTTPD, is called from psgi file.

=head1 INSTANCE METHODS

=head2 C<B<req>>

C<req()> method is a shortcut to Haineko::HTTPD::Request.

=head2 C<B<res>>

C<res()> method is a shortcut to Haineko::HTTPD::Response.

=head2 C<B<rdr( I<Code> I<URL> ])>>

C<rdr()> method is for redirecting to the specified URL.

=head3 Arguments

=head4 B<CODE> HTTP status code

HTTP status code for redirecting. If it is omitted, 302 will be used.

=head4 B<URL> URL to redirect


=head2 C<B<err( [ I<Code> [, I<Message>] ] )>>

C<err()> method is for making error response and returns Haineko::HTTPD::Response object.

=head3 Arguments

=head4 B<CODE> HTTP status code

HTTP status code for responding error. If it is omitted, 404 will be used.

=head4 B<Message> Error message

Error message. If it is omitted, 'Not Found' will be used.


=head2 C<B<r>>

C<r()> method is a dispatcher to each controller, is called from C<Haineko->start().>

=head1 SEE ALSO

=over 2

=item *
L<Haineko::HTTPD::Request> - Child class of Plack::Request

=item *
L<Haineko::HTTPD::Response> - Child class of Plack::Response

=item *
L<Haineko::HTTPD::Router> - Child class of Router::Simple

=back

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
