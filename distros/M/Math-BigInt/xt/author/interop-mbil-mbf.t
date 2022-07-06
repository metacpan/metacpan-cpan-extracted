# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;

use Math::BigFloat;

eval { require Math::BigInt::Lite; };
plan skip_all => "Math::BigInt::Lite required for thie test"
  if $@;

plan tests => 5;

my $x = Math::BigInt::Lite -> new("12");
is(ref($x), "Math::BigInt::Lite", '$x is a Math::BigInt::Lite');

my $gcd = Math::BigFloat::bgcd($x, 18);
is(ref($gcd), "Math::BigFloat", '$gcd is a Math::BigFloat');
is($gcd, "6", '$gcd is 6');

my $lcm = Math::BigFloat::blcm($x, 18);
is(ref($lcm), "Math::BigFloat", '$lcm is a Math::BigFloat');
is($lcm, "36", '$gcd is 36');
