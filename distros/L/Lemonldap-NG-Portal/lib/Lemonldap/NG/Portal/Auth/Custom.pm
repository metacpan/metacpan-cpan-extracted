package Lemonldap::NG::Portal::Auth::Custom;
use Lemonldap::NG::Portal::Lib::CustomModule;

use strict;

our @ISA = qw(Lemonldap::NG::Portal::Lib::CustomModule);
use constant {
    custom_name       => "Auth",
    custom_config_key => "customAuth",
};

1;
