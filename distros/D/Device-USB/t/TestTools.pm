package TestTools;

# Library utility for testing
#

use strict;
use warnings;

#
# Find a particular unique installed device.
#
# which - the number of the unique installed device.
#    0 = first, 1 = second, etc.
# busses - list of busses to check
#
# Ignore any device with the same vendor/product id pair.
# Look only at the unique devices, or the first of non-unique devices.
# 
sub find_an_installed_device
{
    my $which = shift;
    my @uniqs = ();

    foreach my $bus (@_)
    {
        next unless @{$bus->devices()};
        foreach my $dev ($bus->devices())
        {
            my $vendor = $dev->idVendor();
            my $product = $dev->idProduct();
            next if grep { $_->[0] == $vendor and $_->[1] == $product }
                    @uniqs;
            return $dev unless $which--;
            push @uniqs, [ $vendor, $product ];
        }
    }

    return;
}

#
# Find a particular unique installed device with its bus.
#
# which - the number of the unique installed device.
#    0 = first, 1 = second, etc.
# busses - list of busses to check
#
# Ignore any device with the same vendor/product id pair.
# Look only at the unique devices, or the first of non-unique devices.
# 
sub find_an_installed_device_and_bus
{
    my $which = shift;
    my @uniqs = ();

    foreach my $bus (@_)
    {
        next unless @{$bus->devices()};
        foreach my $dev ($bus->devices())
        {
            my $vendor = $dev->idVendor();
            my $product = $dev->idProduct();
            next if grep { $_->[0] == $vendor and $_->[1] == $product }
                    @uniqs;
            return ($bus, $dev) unless $which--;
            push @uniqs, [ $vendor, $product ];
        }
    }

    return;
}

1;
