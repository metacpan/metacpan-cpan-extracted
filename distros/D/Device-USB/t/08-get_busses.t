#!perl -T

use Test::More qw(no_plan); ## no critic(ProhibitNoPlan)
use Device::USB;
use strict;
use warnings;

#
# No plan, because the number of tests depends on the number of
#  busses and devices on the system.
#

my $usb = Device::USB->new();

ok( defined $usb, "Object successfully created" );
can_ok( $usb, "get_busses" );

$usb->find_busses();
$usb->find_devices();

my $busses = $usb->get_busses();
ok( defined $busses, "USB busses found" );

isa_ok( $busses, "ARRAY", "An array of busses returned." );

foreach my $bus (@{$busses})
{
    isa_ok( $bus, "Device::USB::Bus" );
}
