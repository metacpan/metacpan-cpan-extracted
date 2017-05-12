#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 4;

use Math::BigNum qw(:all);

like(e,  qr/^2\.718/);
like(pi, qr/^3\.1415/);

is(factorial(4), 24);
is(binomial(10, 4), 210);
