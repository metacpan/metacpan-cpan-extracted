package Lemonldap::NG::Portal::Password::Demo;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_ERROR
  PE_PASSWORD_OK
);

extends 'Lemonldap::NG::Portal::Password::Base';

our $VERSION = '2.0.16';

sub init {
    my ($self) = @_;
    return $self->SUPER::init;
}

sub confirm {
    my ( $self, $req, $pwd ) = @_;
    return ( $pwd eq $req->{sessionInfo}->{uid} );
}

sub modifyPassword {

    # Nothing to do here, all new passwords are accepted
    return PE_PASSWORD_OK;
}

1;
