package Lemonldap::NG::Portal::UserDB::Choice;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(PE_FIRSTACCESS);

our $VERSION = '2.0.11';

extends 'Lemonldap::NG::Portal::Lib::Choice';

# INITIALIZATION

sub init {
    return $_[0]->SUPER::init(1);
}

# RUNNING METHODS

sub getUser {
    my ( $self, $req, %args ) = @_;
    $self->checkChoice($req) or return PE_FIRSTACCESS;
    my $res = $req->data->{enabledMods1}->[0]->getUser( $req, %args );
    delete $req->pdata->{_choice} if ( $res > 0 );
    return $res;
}

sub findUser {
    my ( $self, $req, %args ) = @_;
    $self->checkChoice($req) or return PE_FIRSTACCESS;
    my $res = $req->data->{enabledMods1}->[0]->findUser( $req, %args );
    delete $req->pdata->{_choice} if ( $res > 0 );
    return $res;
}

sub setSessionInfo {
    my $res = $_[1]->data->{enabledMods1}->[0]->setSessionInfo( $_[1] );
    delete $_[1]->pdata->{_choice} if ( $res > 0 );
    return $res;
}

sub setGroups {
    $_[0]->checkChoice( $_[1] );
    my $res = $_[1]->data->{enabledMods1}->[0]->setGroups( $_[1] );
    delete $_[1]->pdata->{_choice} if ( $res > 0 );
    return $res;
}

1;
