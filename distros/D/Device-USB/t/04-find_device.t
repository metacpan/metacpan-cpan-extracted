#!perl -T

use lib "t";
use TestTools;
use Test::More tests => 8;
use Device::USB;
use strict;
use warnings;

my $usb = Device::USB->new();

ok( defined $usb, "Object successfully created" );
can_ok( $usb, "find_device" );

ok( !defined $usb->find_device( 0xFFFF, 0xFFFF ), "No device found" );

my $busses = $usb->list_busses();
ok( defined $busses, "USB busses found" );

my $found_device = TestTools::find_an_installed_device( 0, @{$busses} );

SKIP:
{
    skip "No USB devices installed", 4 unless defined $found_device;

    my $vendor = $found_device->idVendor();
    my $product = $found_device->idProduct();

    my $dev = $usb->find_device( $vendor, $product );

    ok( defined $dev, "Device found." );
    is_deeply( $dev, $found_device, "first device matches" );

    my $count = @{$busses};
    skip "Only one USB device installed", 2 if $count < 2;

    $found_device = undef;
    for(my $i = 1; $i < $count; ++$i)
    {
        my $dev = TestTools::find_an_installed_device( $i, @{$busses} );
        next unless defined $dev;

        # New vendor/product combination
        if($vendor != $dev->idVendor() || $product != $dev->idProduct())
        {
            $found_device = $dev;
            last;
        }
    }

    skip "No accessible device found", 2 unless defined $found_device;
    $vendor = $found_device->idVendor();
    $product = $found_device->idProduct();

    $dev = $usb->find_device( $vendor, $product );

    ok( defined $dev, "Device found." );
    is_deeply( $dev, $found_device, "second device matches" );
}

