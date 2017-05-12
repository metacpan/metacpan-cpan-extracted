#!perl -T

use Test::More tests => 18;
use Device::USB;
use strict;
use warnings;

can_ok( 'Device::USB', qw/CLASS_PER_INSTANCE/ );
is( Device::USB::CLASS_PER_INSTANCE, 0, "CLASS_PER_INSTANCE value" );
can_ok( 'Device::USB', qw/CLASS_AUDIO/ );
is( Device::USB::CLASS_AUDIO, 1, "CLASS_AUDIO value" );
can_ok( 'Device::USB', qw/CLASS_COMM/ );
is( Device::USB::CLASS_COMM, 2, "CLASS_COMM value" );
can_ok( 'Device::USB', qw/CLASS_HID/ );
is( Device::USB::CLASS_HID, 3, "CLASS_HID value" );
can_ok( 'Device::USB', qw/CLASS_PRINTER/ );
is( Device::USB::CLASS_PRINTER, 7, "CLASS_PRINTER value" );
can_ok( 'Device::USB', qw/CLASS_MASS_STORAGE/ );
is( Device::USB::CLASS_MASS_STORAGE, 8, "CLASS_MASS_STORAGE value" );
can_ok( 'Device::USB', qw/CLASS_HUB/ );
is( Device::USB::CLASS_HUB, 9, "CLASS_HUB value" );
can_ok( 'Device::USB', qw/CLASS_DATA/ );
is( Device::USB::CLASS_DATA, 10, "CLASS_DATA value" );
can_ok( 'Device::USB', qw/CLASS_VENDOR_SPEC/ );
is( Device::USB::CLASS_VENDOR_SPEC, 0xff, "CLASS_VENDOR_SPEC value" );

