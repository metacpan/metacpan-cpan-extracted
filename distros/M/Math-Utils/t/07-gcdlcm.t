#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More tests => 4;

use Math::Utils qw(:utility);

my $factor;

$factor = gcd(29, 3);
ok($factor == 1, "gcd(29, 3) returned $factor");

$factor = gcd(4095, 45);
ok($factor == 45, "gcd(4095, 45) returned $factor");

$factor = hcf(72, [12, 9]);
ok($factor == 3, "hcf(72, [12, 9]) returned $factor");

$factor = hcf(803151, 36, 18, 9);
ok($factor == 9, "hcf(803151, 36, 18, 9) returned $factor");

