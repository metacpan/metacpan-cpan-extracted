package Lemonldap::NG::Portal::UserDB::Null;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants;

extends 'Lemonldap::NG::Common::Module';

our $VERSION = '2.0.0';

# INITIALIZATION

sub init {
    1;
}

# RUNNING METHODS

sub getUser {
    PE_OK;
}

sub findUser {
    PE_OK;
}

sub setSessionInfo {
    PE_OK;
}

sub setGroups {
    PE_OK;
}

1;
