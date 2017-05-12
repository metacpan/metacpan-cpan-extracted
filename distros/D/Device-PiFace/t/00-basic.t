#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

plan tests => 5;

require_ok 'Device::PiFace'
    or BAIL_OUT "Can't load Device::PiFace!";

can_ok 'Device::PiFace', qw[
    new open close read write enable_interrupts disable_interrupts
    wait_for_input mask_has_pins get_mask fd hw_addr
];

# Test bitwise methods
is Device::PiFace->get_mask (0 .. 7), 0xFF, 'get_mask(0..7) == 0xFF';
ok Device::PiFace->mask_has_pins (0xFF, 0 .. 7), 'mask 0xFF has all pins turned on';
ok Device::PiFace->mask_has_pins (0x1, 0), 'mask 0x1 has only pin 0 turned on';
