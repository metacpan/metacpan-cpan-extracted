package Lemonldap::NG::Handler::ApacheMP2::Request;

use strict;
use base 'Lemonldap::NG::Common::PSGI::Request';
use Plack::Util;
use URI;
use URI::Escape;

our $VERSION = '2.21.0';

# Build Plack::Request (inspired from Plack::Handler::Apache2)
sub new {
    my ( $class, $r ) = @_;

    # $r->subprocess_env breaks header modification. That's why it is not used
    # here
    my ( $uri, $args ) = ( $r->uri, $r->args );
    my $uri_full = $uri . ( $args ? "?$args" : '' );
    my $env      = {

        #%ENV,
        HTTP_HOST      => $r->hostname,
        REMOTE_ADDR    => $r->useragent_ip,
        QUERY_STRING   => $args,
        REQUEST_URI    => $uri_full,
        PATH_INFO      => '',
        SERVER_PORT    => $ENV{SERVER_PORT} || $r->get_server_port,
        REQUEST_METHOD => $r->method,
        UNIQUE_ID      => $r->subprocess_env('UNIQUE_ID'),
        'psgi.version'    => [ 1, 1 ],
        'psgi.url_scheme' => ( $ENV{HTTPS} || 'off' ) =~ /^(?:on|1)$/i
        ? 'https'
        : 'http',
        'psgi.input'             => $r,
        'psgi.errors'            => *STDERR,
        'psgi.multithread'       => Plack::Util::FALSE,
        'psgi.multiprocess'      => Plack::Util::TRUE,
        'psgi.run_once'          => Plack::Util::FALSE,
        'psgi.streaming'         => Plack::Util::TRUE,
        'psgi.nonblocking'       => Plack::Util::FALSE,
        'psgix.harakiri'         => Plack::Util::TRUE,
        'psgix.cleanup'          => Plack::Util::TRUE,
        'psgix.cleanup.handlers' => [],
        'psgi.r'                 => $r,
    };
    $r->headers_in->do(
        sub {
            my $h = shift;
            my $k = uc($h);
            if ( $k ne 'HOST' ) {
                $k =~ s/-/_/g;
                $env->{"HTTP_$k"} = $r->headers_in->{$h};
            }
            return 1;
        }
    );
    my $uri = URI->new( "http://" . $r->hostname . $r->unparsed_uri );
    $env->{PATH_INFO} = uri_unescape( $uri->path );

    my $self = Lemonldap::NG::Common::PSGI::Request->new($env);
    bless $self, $class;
    return $self;
}

sub data {
    my ($self) = @_;
    return $self->{data} ||= {};
}

sub wantJSON {
    return 1
      if ( defined $_[0]->env->{HTTP_ACCEPT}
        and $_[0]->env->{HTTP_ACCEPT} =~ m#(?:application|text)/json#i );
    return 0;
}

sub request_id { return $_[0]->env->{UNIQUE_ID} }

1;
