# LLNG platform class for FastCGI handler (Nginx)
#
# See https://lemonldap-ng.org/documentation/latest/handlerarch
package Lemonldap::NG::Handler::Server;

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

## @method void _run()
# Return subroutine that add headers stored in $req->{respHeaders} in
# response returned by handler()
#
sub _run {
    my ($self) = @_;
    return sub {
        my $req = Lemonldap::NG::Common::PSGI::Request->new( $_[0] );
        my $res = $self->_logAuthTrace($req);
        push @{ $res->[1] }, $req->spliceHdrs,
          Cookie => ( $req->{Cookie} // '' );
        return $res;
    };
}

## @method PSGI-Response handler($req)
# If PSGI is used as an authentication FastCGI only, this method will be
# called for authenticated users and returns only 200. Headers are set by
# Lemonldap::NG::Handler::PSGI.
# @param $req Lemonldap::NG::Common::PSGI::Request
sub handler {
    return [ 200, [ 'Content-Length', 0 ], [] ];
}

1;
