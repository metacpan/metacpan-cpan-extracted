# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 6;

use Math::BigInt;

note("is_zero() as a class method");

is(Math::BigInt -> is_zero(0), 1,
   "Math::BigInt -> is_zero(0)");

is(Math::BigInt -> is_zero(1), 0,
   "Math::BigInt -> is_zero(1)");

is(Math::BigInt -> is_zero(Math::BigInt -> bzero()), 1,
   "Math::BigInt -> is_zero(Math::BigInt -> bzero())");

is(Math::BigInt -> is_zero(Math::BigInt -> bone()), 0,
   "Math::BigInt -> is_zero(Math::BigInt -> bone())");

note("is_zero() as an instance method");

is(Math::BigInt -> bzero() -> is_zero(), 1,
   "Math::BigInt -> bzero() -> is_zero()");

is(Math::BigInt -> bone() -> is_zero(), 0,
   "Math::BigInt -> bone() -> is_zero()");
