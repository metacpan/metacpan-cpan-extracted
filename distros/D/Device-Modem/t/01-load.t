#!perl

use strict;
use warnings;
use Test::More tests => 6;

BEGIN {
    use_ok('Device::Modem') or BAIL_OUT("Can't use module");
    use_ok('Device::Modem::UsRobotics') or BAIL_OUT("Can't use module");
    use_ok('Device::Modem::Protocol::Xmodem') or BAIL_OUT("Can't use module");
    use_ok('Device::Modem::Log::File') or BAIL_OUT("Can't use module");
    use_ok('Device::Modem::Log::Syslog') or BAIL_OUT("Can't use module");
}

can_ok('Device::Modem', qw(new));
