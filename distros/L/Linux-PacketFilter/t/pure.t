#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use_ok('Linux::PacketFilter');

my $filter = Linux::PacketFilter->new(
    [ 'ld k_N', 0x80000000 ],
    [ 'ld k_n', 0x8000 ],
);

# Only for testing; don’t read $filter internals in production code!
my $raw = $filter->[1];

my ($num32, $num16) = unpack( 'x4 N x4 N', $raw );

is( $num32, 0x80000000, '32-bit byte order saved' );
is( $num16, 0x8000 << 16, '16-bit byte order saved' );

done_testing();

1;
