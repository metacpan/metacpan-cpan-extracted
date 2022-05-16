# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 12;

use Math::BigInt;

note("beq() as a class method");

is(Math::BigInt -> beq(5, 5), 1,
   "Math::BigInt -> beq(5, 5)");

is(Math::BigInt -> beq(5, 7), "",
   "Math::BigInt -> beq(5, 7)");

is(Math::BigInt -> beq(Math::BigInt -> new(5), 5), 1,
   "Math::BigInt -> beq(Math::BigInt -> new(5), 5)");

is(Math::BigInt -> beq(Math::BigInt -> new(5), 7), "",
   "Math::BigInt -> beq(Math::BigInt -> new(5), 7)");

is(Math::BigInt -> beq(5, Math::BigInt -> new(5)), 1,
   "Math::BigInt -> beq(5, Math::BigInt -> new(5))");

is(Math::BigInt -> beq(5, Math::BigInt -> new(7)), "",
   "Math::BigInt -> beq(5, Math::BigInt -> new(7))");

is(Math::BigInt -> beq(Math::BigInt -> new(5), Math::BigInt -> new(5)), 1,
   "Math::BigInt -> beq(Math::BigInt -> new(5), Math::BigInt -> new(5))");

is(Math::BigInt -> beq(Math::BigInt -> new(5), Math::BigInt -> new(7)), "",
   "Math::BigInt -> beq(5, Math::BigInt -> new(7))");

note("beq() as an instance method");

is(Math::BigInt -> new(5) -> beq(5), 1,
   "Math::BigInt -> new(5) -> beq(5)");

is(Math::BigInt -> new(5) -> beq(7), "",
   "Math::BigInt -> new(5) -> beq(7)");

is(Math::BigInt -> new(5) -> beq(Math::BigInt -> new(5)), 1,
   "Math::BigInt -> new(5) -> beq(Math::BigInt -> new(5))");

is(Math::BigInt -> new(5) -> beq(Math::BigInt -> new(7)), "",
   "Math::BigInt -> new(5) -> beq(Math::BigInt -> new(7))");
