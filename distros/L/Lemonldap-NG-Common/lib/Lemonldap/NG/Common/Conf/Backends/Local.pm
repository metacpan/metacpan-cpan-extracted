package Lemonldap::NG::Common::Conf::Backends::Local;

use strict;
use Lemonldap::NG::Common::Conf::Constants;

our $VERSION = '2.0.14';

sub prereq {
    return 1;
}

sub available {
    return 1;
}

sub lastCfg {
    return 1;
}

sub isLocked {
    return 1;
}

sub unlock {
    return 1;
}

sub store {
    $Lemonldap::NG::Common::Conf::msg = 'Read-only backend!';
    return DATABASE_LOCKED;
}

sub load {
    return {
        cfgNum    => 1,
        cfgDate   => time,
        cfgAuthor => 'LLNG Team',
        cfgLog    =>
q"Do not edit this configuration, Null backend uses lemonldap-ng.ini values only",
    };
}

sub delete {
    $Lemonldap::NG::Common::Conf::msg = 'Read-only backend!';
    return 0;
}

1;
