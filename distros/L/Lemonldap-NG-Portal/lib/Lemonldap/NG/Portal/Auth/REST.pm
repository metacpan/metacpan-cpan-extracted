package Lemonldap::NG::Portal::Auth::REST;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_ERROR
  PE_BADCREDENTIALS
  PE_OK
);

our $VERSION = '2.0.3';

extends 'Lemonldap::NG::Portal::Auth::_WebForm',
  'Lemonldap::NG::Portal::Lib::REST';

# INITIALIZATION

sub init {
    my $self = shift;

    # Add warning in log
    unless ( $self->conf->{restAuthUrl} ) {
        $self->logger->error('No Auth REST URL given');
        return 0;
    }

    return $self->Lemonldap::NG::Portal::Auth::_WebForm::init();
}

sub authenticate {
    my ( $self, $req ) = @_;
    my $res = eval {
        $self->restCall( $self->conf->{restAuthUrl},
            { user => $req->user, password => $req->data->{password} } );
    };
    if ($@) {
        $self->logger("Auth error: $@");
        $self->setSecurity($req);
        return PE_ERROR;
    }
    unless ( $res->{result} ) {
        $self->userLogger->warn(
            "Bad credentials for " . $req->user . ' (' . $req->address . ')' );
        $self->setSecurity($req);
        return PE_BADCREDENTIALS;
    }
    $req->data->{restAuthInfo} = $res->{info} || {};
    return PE_OK;
}

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;
    $self->SUPER::setAuthSessionInfo($req);
    $req->sessionInfo->{$_} = $req->data->{restAuthInfo}->{$_}
      foreach ( keys %{ $req->data->{restAuthInfo} } );
    $req->sessionInfo->{authenticationLevel} = $self->conf->{restAuthnLevel};
    return PE_OK;
}

sub authLogout {
    PE_OK;
}

1;
