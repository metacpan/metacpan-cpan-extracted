package Lemonldap::NG::Portal::Auth::Apache;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(PE_ERROR PE_OK);

our $VERSION = '2.0.0';

extends 'Lemonldap::NG::Portal::Main::Auth';

# INITIALIZATION

sub init {
    1;
}

# RUNNING METHODS

sub extractFormInfo {
    my ( $self, $req ) = @_;
    unless ( $req->{user} = $req->env->{REMOTE_USER} ) {
        $self->logger->error('Apache is not configured to authenticate users!');
        return PE_ERROR;
    }

    # This is needed for Kerberos authentication
    $req->{user} =~ s/^(.*)@.*$/$1/g;
    PE_OK;
}

sub authenticate {
    PE_OK;
}

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;
    $req->{sessionInfo}->{authenticationLevel} =
      $self->conf->{apacheAuthnLevel};
    PE_OK;
}

sub authLogout {
    PE_OK;
}

sub getDisplayType {
    return 'logo';
}

1;
