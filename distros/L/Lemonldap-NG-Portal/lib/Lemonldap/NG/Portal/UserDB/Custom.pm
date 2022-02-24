package Lemonldap::NG::Portal::UserDB::Custom;
use Lemonldap::NG::Portal::Lib::CustomModule;

use strict;

our @ISA = qw(Lemonldap::NG::Portal::Lib::CustomModule);
use constant {
    custom_name       => "UserDB",
    custom_config_key => "customUserDB",
};

1;
