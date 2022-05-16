# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 12;

use Math::BigInt;

note("batan() as a class method");

cmp_ok(Math::BigInt -> batan("-inf"), "==", -1,
       'Math::BigInt -> batan("-inf")');

cmp_ok(Math::BigInt -> batan("-2"), "==", -1,
       'Math::BigInt -> batan("-2")');

cmp_ok(Math::BigInt -> batan(0), "==", 0,
       'Math::BigInt -> batan(0)');

cmp_ok(Math::BigInt -> batan("2"), "==", 1,
       'Math::BigInt -> batan("2")');

cmp_ok(Math::BigInt -> batan("inf"), "==", 1,
       'Math::BigInt -> batan("inf")');

is(Math::BigInt -> batan("NaN"), "NaN",
   'Math::BigInt -> batan("NaN")');

note("batan() as an instance method");

cmp_ok(Math::BigInt -> new("-inf") -> batan(), "==", -1,
       'Math::BigInt -> new("-inf")');

cmp_ok(Math::BigInt -> new("-2") -> batan(), "==", -1,
       'Math::BigInt -> new("-2")');

cmp_ok(Math::BigInt -> new(0) -> batan(), "==", 0,
       'Math::BigInt -> new(0)');

cmp_ok(Math::BigInt -> new("2") -> batan(), "==", 1,
       'Math::BigInt -> new("2")');

cmp_ok(Math::BigInt -> new("inf") -> batan(), "==", 1,
       'Math::BigInt -> new("inf")');

is(Math::BigInt -> new("NaN") -> batan(), "NaN",
   'Math::BigInt -> new("NaN")');
