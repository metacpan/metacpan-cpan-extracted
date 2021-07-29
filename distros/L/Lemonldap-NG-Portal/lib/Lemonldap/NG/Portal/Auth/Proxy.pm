package Lemonldap::NG::Portal::Auth::Proxy;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK);

our $VERSION = '2.0.12';

extends 'Lemonldap::NG::Portal::Auth::_WebForm';

# INITIALIZATION

sub init {
    my $self = shift;
    return 0 unless $self->Lemonldap::NG::Portal::Auth::_WebForm::init();
    if ( $self->conf->{proxyUseSoap} ) {
        extends 'Lemonldap::NG::Portal::Lib::SOAPProxy',
          'Lemonldap::NG::Portal::Auth::_WebForm';
    }
    else {
        extends 'Lemonldap::NG::Portal::Lib::RESTProxy',
          'Lemonldap::NG::Portal::Auth::_WebForm';
    }
    return $self->SUPER::init();
}

# RUNNING METHODS

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;
    $req->{sessionInfo}->{authenticationLevel} = $self->conf->{proxyAuthnLevel};
    return PE_OK;
}

sub getDisplayType {
    return "standardform";
}

1;
