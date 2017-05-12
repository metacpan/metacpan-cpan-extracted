#!/bin/bin/perl
#
# Copyright (C) 2013 by Lieven Hollevoet

# This test runs basic module tests

use strict;
use Test::More;

BEGIN { use_ok 'Device::Microchip::Bootloader'; }
BEGIN { use_ok 'Test::Exception'; }
require Test::Exception;

# Check we get an error message on missing input parameters
my $loader;

can_ok ('Device::Microchip::Bootloader', qw(firmware device));

throws_ok { $loader = Device::Microchip::Bootloader->new() } qr/Attribute .+ is required at constructor/, "Checking missing parameters";
throws_ok { $loader = Device::Microchip::Bootloader->new(firmware => 't/stim/test.hex') } qr/Attribute \(device\) is required at constructor/, "Checking missing target device";
throws_ok { $loader = Device::Microchip::Bootloader->new(device => 'flubber') } qr/Attribute \(firmware\) is required at constructor/, "Checking missing HEX file input";
throws_ok { $loader = Device::Microchip::Bootloader->new(firmware => 't/stim/missing_file.hex', device => 'flubber') } qr/Can't open .+ for reading/, "Checking missing hex file";

$loader = Device::Microchip::Bootloader->new(firmware => 't/stim/test.hex', device => '/dev/ttyUSB0');
ok $loader, 'object created';
ok $loader->isa('Device::Microchip::Bootloader'), 'and it is the right class';

done_testing();
