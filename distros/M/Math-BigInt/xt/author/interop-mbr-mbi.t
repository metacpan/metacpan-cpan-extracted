# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;

use Math::BigInt;

eval { require Math::BigRat; };
plan skip_all => "Math::BigRat required for thie test"
  if $@;

plan tests => 5;

my $x = Math::BigRat -> new("12");
is(ref($x), "Math::BigRat", '$x is a Math::BigRat');

my $gcd = Math::BigInt::bgcd($x, 18);
is(ref($gcd), "Math::BigInt", '$gcd is a Math::BigInt');
is($gcd, "6", '$gcd is 6');

my $lcm = Math::BigInt::blcm($x, 18);
is(ref($lcm), "Math::BigInt", '$lcm is a Math::BigInt');
is($lcm, "36", '$gcd is 36');
