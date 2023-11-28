# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 12;

use Math::BigInt;

# The default is to truncate to integer, and since sqrt(3) = 1.732..., the
# output should be 1.

is(Math::BigInt -> new(3) -> bsqrt(), "1",
   "Math::BigInt -> new(3) -> bsqrt() = 1");

# When upgrading is not enabled, the output should be truncated.

for (my $i = 10 ; $i <= 100 ; $i += 10) {
    my $in  = "9" x (2 * $i);
    my $out = "9" x $i;
    is(Math::BigInt -> new($in) -> bsqrt(), $out,
       qq|Math::BigInt -> new("$in") -> bsqrt()|);
}

# When the user has specified an accuracy of 1, the output should be rounded to
# the nearest integer, and since sqrt(3) = 1.732..., the output should be 2.

require Math::BigFloat;
Math::BigInt -> upgrade("Math::BigFloat");

is(Math::BigInt -> new(3) -> bsqrt(1), "2",
   "Math::BigInt -> new(3) -> bsqrt(1) = 2");
