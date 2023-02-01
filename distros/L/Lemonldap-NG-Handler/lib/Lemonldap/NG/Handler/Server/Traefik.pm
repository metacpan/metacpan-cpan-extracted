package Lemonldap::NG::Handler::Server::Traefik;

use strict;
use Mouse;
use Lemonldap::NG::Handler::Server::Main;

our $VERSION = '2.0.6';

extends 'Lemonldap::NG::Handler::PSGI';

sub init {
    my $self = shift;
    $self->api('Lemonldap::NG::Handler::Server::Main');
    my $tmp = $self->SUPER::init(@_);
}

sub _run {
    my $self = shift;
    return sub {
        my $req = $_[0];
        $req->{HTTP_HOST}   = $req->{HTTP_X_FORWARDED_HOST};
        $req->{REQUEST_URI} = $req->{HTTP_X_FORWARDED_URI};
        return $self->_logAuthTrace(
            Lemonldap::NG::Common::PSGI::Request->new($req) );
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
