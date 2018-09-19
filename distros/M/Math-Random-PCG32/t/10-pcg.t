#!perl

use strict;
use warnings;

use Test::Most;    # plan is down at bottom
my $deeply = \&eq_or_diff;

use Math::Random::PCG32;

can_ok( 'Math::Random::PCG32', qw(new rand) );

my $rng = Math::Random::PCG32->new( 42, 54 );

# these at least agree with the "pcg32-demo" output compiled from
# https://github.com/imneme/pcg-c-basic as of commit bc39cd7
$deeply->(
    [ map $rng->rand, 1 .. 6 ],

    [ 0xa15c02b7, 0x7b47f409, 0xba1d3330, 0x83d2f293, 0xbfa4784b, 0xcbed606e ]
);

plan tests => 2
