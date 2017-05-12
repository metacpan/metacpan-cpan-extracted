#!/bin/bin/perl
#
# Copyright (C) 2013 by Lieven Hollevoet

# This test runs tests for testing bugreports and feature requests

use strict;

use Test::More;
BEGIN { use_ok 'Test::Exception'; }
require Test::Exception;

BEGIN { use_ok('Device::Microchip::Bootloader'); }

# Ticket #1: we should ensure the user does not try to load firmware over the bootloader
my $loader;

throws_ok {$loader = Device::Microchip::Bootloader->new(firmware => 't/stim/high_code.hex', device => '/dev/ttyUSB0', verbose => 3 ) } qr/HEX inputfile contains instructions on locations that would overwrite the bootloader/, "Detected overwrite attempt of the bootloader";

# And we should not get that message when loading a regular hex file
$loader = Device::Microchip::Bootloader->new(
    firmware => 't/stim/short.hex',
    device   => '/dev/ttyUSB0',
    verbose  => 3
    );
ok $loader, 'object created OK and no warning created';


done_testing();
