#!/usr/bin/env perl 

use strict;
use warnings;
BEGIN {
    push @INC, ('blib/lib', 'blib/arch');
}
use lib '../lib';
use blib;

use Device::Cdio::Device;
use Test::More tests => 3;
note 'Test getting a default device driver';

my $result1=Device::Cdio::get_default_device_driver($perlcdio::DRIVER_DEVICE);
my $result2=Device::Cdio::get_default_device_driver();
ok (!defined($result1) || $result1 eq $result2,
    "get_default_device_driver with/without parameter" );

my $device = Device::Cdio::Device->new();
$result1= $device->get_device();
ok (!defined($result1) || $result1 eq $result2,
    'get_default_device_driver() == $d->get_device()' );
if (defined($result2)) {
    # Now try using array return form
    my ($driver1, $driver2);
    ($result1, $driver1)=Device::Cdio::get_default_device_driver();
    my $device = Device::Cdio::Device->new(-driver_id=>$driver1);
    $result2 = $device->get_device();
    ok ($result1 eq $result2,
	"array form of get_default_device_driver" );
} else {
    # Didn't find any default device. So we have to skip this.
    ok(1, "get_default_device_driver array form skipped - no device");
}
