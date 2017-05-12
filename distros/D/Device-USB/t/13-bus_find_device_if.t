#!perl -T

use lib "t";
use TestTools;
use Test::More tests => 8;
use Device::USB;
use strict;
use warnings;

my $usb = Device::USB->new();
ok( defined $usb, "Object successfully created" );

my $bus = ($usb->list_busses())[0];

SKIP:
{
    skip "No USB buses found.", 7 unless defined $bus;

    eval { $bus->find_device_if() };
    like( $@, qr/Missing predicate/, "Requires a predicate." );

    eval { $bus->find_device_if( 1 ) };
    like( $@, qr/Predicate must be/, "Requires a code reference." );

    my $busses = $usb->list_busses();
    ok( defined $busses, "USB busses found" );

    my ($found_bus, $found_device) =
        TestTools::find_an_installed_device_and_bus( 0, @{$busses} );

    skip "No USB devices installed", 4 unless defined $found_device;

    my $vendor = $found_device->idVendor();
    my $product = $found_device->idProduct();

    my $dev = $found_bus->find_device_if(
        sub { $vendor == $_->idVendor() && $product == $_->idProduct() }
    );

    ok( defined $dev, "Device found." );
    is_deeply( $dev, $found_device, "first device matches" );

    my $count = @{$busses};
    skip "Only one USB device installed", 2 if $count < 2;

    ($found_bus, $found_device) =
        TestTools::find_an_installed_device_and_bus( 1, @{$busses} );

    skip "No accessible device found", 2 unless defined $found_device;
    $vendor = $found_device->idVendor();
    $product = $found_device->idProduct();

    $dev = $found_bus->find_device_if(
        sub { $vendor == $_->idVendor() && $product == $_->idProduct() }
    );

    ok( defined $dev, "Device found." );
    is_deeply( $dev, $found_device, "second device matches" );
}

