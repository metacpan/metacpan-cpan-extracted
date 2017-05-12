package Lemonldap::NG::Handler::PSGI::Server;

use strict;
use Mouse;
use Lemonldap::NG::Handler::SharedConf qw(:tsv);

extends 'Lemonldap::NG::Handler::PSGI';

## @method void _run()
# Return subroutine that add headers stored in $req->{respHeaders} in
# response returned by handler()
#
sub _run {
    my ($self) = @_;
    return sub {
        my $req = Lemonldap::NG::Common::PSGI::Request->new( $_[0] );
        my $res = $self->_authAndTrace($req);
        push @{ $res->[1] }, %{ $req->{respHeaders} },
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
