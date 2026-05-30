package Lemonldap::NG::Portal::Auth::REST;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_BADCREDENTIALS
);

our $VERSION = '2.23.0';

extends qw(
  Lemonldap::NG::Portal::Auth::_WebForm
  Lemonldap::NG::Portal::Lib::REST
);

# INITIALIZATION
sub init {
    my $self = shift;

    if ( not $self->initNamedCallFromConf( 'restAuth', 'auth' ) ) {
        $self->logger->error('No REST Authentication URL given');
        return 0;
    }

    return $self->Lemonldap::NG::Portal::Auth::_WebForm::init();
}

sub authenticate {
    my ( $self, $req ) = @_;
    my $res = eval {
        $self->restNamedCall( $req,
            'auth', { user => $req->user, password => $req->data->{password} },
            {} );
    };
    if ($@) {
        $self->logger->error("Auth error: $@");
        $self->setSecurity($req);
        return PE_ERROR;
    }
    $self->logger->debug( "REST result:" . ( $res->{result} || 'undef' ) );
    if ( $res->{info} ) {
        eval {
            $self->logger->debug(" $_ => $res->{info}->{$_}")
              foreach ( keys %{ $res->{info} } );
        };
    }
    $self->logger->error( 'No "info": ' . $@ ) if ($@);
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
    return PE_OK;
}

1;
