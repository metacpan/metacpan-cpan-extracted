package Lemonldap::NG::Portal::Auth::Null;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants;

our $VERSION = '2.0.12';

extends 'Lemonldap::NG::Portal::Main::Auth';

# INITIALIZATION

sub init {
    return 1;
}

# RUNNING METHODS

sub extractFormInfo {
    my ( $self, $req ) = @_;
    $req->user('anonymous');
    return PE_OK;
}

sub authenticate {
    return PE_OK;
}

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;
    $req->{sessionInfo}->{'_user'}             = 'anonymous';
    $req->{sessionInfo}->{authenticationLevel} = $self->conf->{nullAuthnLevel};
    return PE_OK;
}

sub authLogout {
    return PE_OK;
}

sub getDisplayType {
    return '';
}

1;
