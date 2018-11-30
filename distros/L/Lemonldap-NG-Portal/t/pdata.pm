package t::pdata;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK);

extends 'Lemonldap::NG::Portal::Main::Plugin';

sub init { 1 }

use constant beforeAuth => 'insert';

sub insert {
    my ( $self, $req ) = @_;
    $req->pdata->{mytest} ||= 0;
    $req->pdata->{mytest}++;
    return PE_OK;
}

1;
