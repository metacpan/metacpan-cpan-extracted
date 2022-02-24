package Lemonldap::NG::Portal::Password::Custom;
use Lemonldap::NG::Portal::Lib::CustomModule;

use strict;

our @ISA = qw(Lemonldap::NG::Portal::Lib::CustomModule);
use constant {
    custom_name       => "Password",
    custom_config_key => "customPassword",
};

1;
