#!perl -T

use Test::More;
use Device::USB;
use strict;
use warnings;

my $usb = Device::USB->new();
if(defined $usb)
{
    my @devices = $usb->list_devices();
    my $num_configs = 0;
    $num_configs += $_->bNumConfigurations() foreach @devices;
    plan tests => 1 + $num_configs*2;
}
else
{
    fail( "Unable to create USB object." );
}

my $busses = $usb->list_busses();
ok( defined $busses, "USB busses found" );

foreach my $bus (@{$busses})
{
    foreach my $dev (@{$bus->devices()})
    {
        my @configs = $dev->configurations();
        my $num_configs = $dev->bNumConfigurations() - 1;
        foreach my $i (0..$num_configs)
        {
            is( $dev->get_configuration( $i ), $configs[$i], "Positive index" );
            is( $dev->get_configuration( -$i ), $configs[-$i], "Negative index" );
        }

    }
}

