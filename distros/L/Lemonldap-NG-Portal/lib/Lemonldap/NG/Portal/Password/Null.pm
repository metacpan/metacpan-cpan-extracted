package Lemonldap::NG::Portal::Password::Null;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_PASSWORD_OK
);

extends 'Lemonldap::NG::Portal::Password::Base';

our $VERSION = '2.0.0';

sub init { 1 }

sub confirm { 1 }

sub modifyPassword {
    PE_PASSWORD_OK;
}

1;
