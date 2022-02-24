package Lemonldap::NG::Portal::Register::Custom;
use Lemonldap::NG::Portal::Lib::CustomModule;

use strict;

our @ISA = qw(Lemonldap::NG::Portal::Lib::CustomModule);
use constant {
    custom_name       => "Register",
    custom_config_key => "customRegister",
};

1;
