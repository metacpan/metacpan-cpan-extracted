#!/usr/bin/env perl
use strict;
use warnings;
use Device::PiFace ':piface_constants';
use Test::More;
use Time::HiRes 'sleep';

plan tests => 4 + 8;

my $piface = Device::PiFace->new (hw_addr => $ENV{PIFACE_HARDWARE_ADDRESS} // 0);

# Ensure that everything is turned off
$piface->write (value => 0);
is $piface->read (register => OUTPUT), 0, 'everything is turned off';

# Test the 8 output pins
for (0 .. 7)
{
    $piface->write   (pin => $_, value => 1);
    is $piface->read (pin => $_, register => OUTPUT), 1, "pin $_ reacts correctly";
    sleep (0.4);
}

# Ensure that everything is now turned on
is $piface->read (register => OUTPUT), 0xFF, 'everything is turned on';

# Test bitmasks (value: 0b10101010)
$piface->write (value => $piface->get_mask (qw(1 3 5 7)));
my $mask = $piface->read (register => OUTPUT);
is $mask, 0xAA, 'mask == 0xAA (4 pins turned on)';
ok $piface->mask_has_pins ($mask, qw(1 3 5 7)), 'mask_has_pins agrees with us (mask == 0xAA)';

# Testing done, cleanup
$piface->write (value => 0);
