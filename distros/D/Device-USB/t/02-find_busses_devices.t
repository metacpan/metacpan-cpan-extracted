#!perl -T

use Test::More tests => 4;
use Device::USB;
use strict;
use warnings;

my $usb = Device::USB->new();

ok( defined $usb, "Object successfully created" );
can_ok( $usb, "find_busses", "find_devices" );

my $bus_changes = $usb->find_busses();
is( $usb->find_busses(), 0, "No bus changes since last call." );

my $device_changes = $usb->find_devices();
is( $usb->find_devices(), 0, "No device changes since last call." );
