package Lemonldap::NG::Portal::Auth::DBI;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_BADCREDENTIALS);

our $VERSION = '2.0.0';

extends 'Lemonldap::NG::Portal::Auth::_WebForm',
  'Lemonldap::NG::Portal::Lib::DBI';

# INTIALIZATION

sub init {
    my ($self) = @_;
    return (  $self->Lemonldap::NG::Portal::Auth::_WebForm::init
          and $self->Lemonldap::NG::Portal::Lib::DBI::init );
}

# RUNNING METHODS

sub authenticate {
    my ( $self, $req ) = @_;
    if ( $self->check_password($req) ) {
        return PE_OK;
    }
    else {
        $self->setSecurity($req);
        return PE_BADCREDENTIALS;
    }
}

sub authLogout {
    PE_OK;
}

1;
