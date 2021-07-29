package Lemonldap::NG::Portal::Auth::DBI;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_BADCREDENTIALS);

our $VERSION = '2.0.12';

extends 'Lemonldap::NG::Portal::Auth::_WebForm',
  'Lemonldap::NG::Portal::Lib::DBI';

# INTIALIZATION

sub init {
    my ($self) = @_;
    foreach (qw(dbiAuthTable dbiAuthLoginCol dbiAuthPasswordCol)) {
        $self->logger->warn( ref($self) . " seems not configured: missing $_" )
          unless $self->conf->{$_};
    }
    return (  $self->Lemonldap::NG::Portal::Auth::_WebForm::init
          and $self->Lemonldap::NG::Portal::Lib::DBI::init );
}

has authnLevel => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{dbiAuthnLevel};
    }
);

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
    return PE_OK;
}

1;
