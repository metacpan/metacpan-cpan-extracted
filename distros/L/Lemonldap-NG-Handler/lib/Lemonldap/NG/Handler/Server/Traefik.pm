package Lemonldap::NG::Handler::Server::Traefik;

use strict;
use Mouse;
use Lemonldap::NG::Handler::Server::Main;

our $VERSION = '2.17.0';

extends 'Lemonldap::NG::Handler::PSGI';

sub init {
    my $self = shift;
    $self->api('Lemonldap::NG::Handler::Server::Main');
    my $tmp = $self->SUPER::init(@_);
}

sub _run {
    my $self = shift;

    # Create regular _authAndTrace PSGI app
    my $app = $self->psgiAdapter(
        sub {
            my $req = $_[0];
            return $self->_authAndTrace($req);
        }
    );

    # Middleware to set correct values for Traefik
    return sub {
        my $env = $_[0];
        $env->{HTTP_HOST}   = $env->{HTTP_X_FORWARDED_HOST};
        $env->{REQUEST_URI} = $env->{HTTP_X_FORWARDED_URI};
        return $app->($env);
    }
}

sub handler {
    my ( $self, $req ) = @_;
    my @convertedHdrs = (
        @{ $req->{respHeaders} },
        'Content-Length' => 0,
        Cookie           => ( $req->env->{HTTP_COOKIE} // '' )
    );
    return [ 200, \@convertedHdrs, [] ];
}

1;
