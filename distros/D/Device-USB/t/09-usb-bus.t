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

my $busses = $usb->list_busses();
ok( defined $busses, "USB busses found" );

can_ok( "Device::USB::Bus", qw/dirname location devices/ );

foreach my $bus (@{$busses})
{
    isa_ok( $bus, "Device::USB::Bus" );
    ok( defined $bus->dirname(), "Dirname returns a value" );
    ok( defined $bus->location, "Location returns a value" );
    my @devices = $bus->devices();
    foreach my $dev (@devices)
    {
        isa_ok( $dev, "Device::USB::Device" );
    }
}
