#!perl -T

use lib "t";
use TestTools;
use Test::More tests => 8;
use Device::USB;
use strict;
use warnings;

my $usb = Device::USB->new();

ok( defined $usb, "Object successfully created" );
can_ok( $usb, "list_devices" );

my $busses = $usb->list_busses();
ok( defined $busses, "USB busses found" );

my $found_device = TestTools::find_an_installed_device( 0, @{$busses} );

SKIP:
{
    skip "No installed USB devices", 5 unless defined $found_device;

    my $vendor = $found_device->idVendor();
    my $product = $found_device->idProduct();

    my @devices = $usb->list_devices( $vendor, $product );
    my $device_count = @devices;

    ok( 0 < $device_count, "At least one device found" );
    my $matches = grep { $_->idVendor() == $vendor && $_->idProduct() == $product }
         @devices;
    is( $matches, $device_count, "All match vendor and product" );
    
    my @vendor_devices = $usb->list_devices( $vendor );
    my $vdevice_count = @vendor_devices;

    ok( $device_count <= $vdevice_count, "At least one device found by vendor" );
    $matches = grep { $_->idVendor() == $vendor } @vendor_devices;
    is( $matches, $vdevice_count, "All vendors match" );

    my @all_devices = $usb->list_devices();
    my $all_count = @all_devices;
    ok( $vdevice_count <= $all_count, "At least one device found" );
}

