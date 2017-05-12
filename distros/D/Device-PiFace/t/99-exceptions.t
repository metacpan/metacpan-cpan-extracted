#!/usr/bin/env perl
use strict;
use warnings;
use Device::PiFace;
use Test::More;

BEGIN { eval 'use Test::Fatal; 1' || plan skip_all => 'Test::Fatal required for this test!'; }

plan tests => 3;

like (
    exception { Device::PiFace->new },
    qr/missing 'hw_addr'/,
    'croak when "hw_addr" is not given to the constructor'
);

like (
    exception { Device::PiFace->write },
    qr/missing 'value'/,
    'croak when "value" is not given to "write"'
);

like (
    exception { Device::PiFace->mask_has_pins (0xFF) },
    qr/specify at least one pin/,
    'croak when "mask_has_pins" has no pins passed to it'
);
