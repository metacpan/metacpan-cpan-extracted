package Lemonldap::NG::Portal::Password::Null;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants 'PE_NO_PASSWORD_BE';

extends 'Lemonldap::NG::Portal::Password::Base';

our $VERSION = '2.0.16';

sub init {
    return 1;
}

sub confirm {
    return 1;
}

sub modifyPassword {
    return PE_NO_PASSWORD_BE;
}

1;
