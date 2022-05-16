# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 18;

use Math::BigInt;

note("blt() as a class method");

is(Math::BigInt -> blt(5, 7), 1,
   "Math::BigInt -> blt(5, 7)");

is(Math::BigInt -> blt(5, 5), "",
   "Math::BigInt -> blt(5, 5)");

is(Math::BigInt -> blt(7, 5), "",
   "Math::BigInt -> blt(7, 5)");

is(Math::BigInt -> blt(Math::BigInt -> new(5), 7), 1,
   "Math::BigInt -> blt(Math::BigInt -> new(5), 7)");

is(Math::BigInt -> blt(Math::BigInt -> new(5), 5), "",
   "Math::BigInt -> blt(Math::BigInt -> new(5), 5)");

is(Math::BigInt -> blt(Math::BigInt -> new(7), 5), "",
   "Math::BigInt -> blt(Math::BigInt -> new(7), 5)");

is(Math::BigInt -> blt(5, Math::BigInt -> new(7)), 1,
   "Math::BigInt -> blt(5, Math::BigInt -> new(7))");

is(Math::BigInt -> blt(5, Math::BigInt -> new(5)), "",
   "Math::BigInt -> blt(5, Math::BigInt -> new(5))");

is(Math::BigInt -> blt(7, Math::BigInt -> new(5)), "",
   "Math::BigInt -> blt(7, Math::BigInt -> new(5))");

is(Math::BigInt -> blt(Math::BigInt -> new(5), Math::BigInt -> new(7)), 1,
   "Math::BigInt -> blt(5, Math::BigInt -> new(7))");

is(Math::BigInt -> blt(Math::BigInt -> new(5), Math::BigInt -> new(5)), "",
   "Math::BigInt -> blt(Math::BigInt -> new(5), Math::BigInt -> new(5))");

is(Math::BigInt -> blt(Math::BigInt -> new(7), Math::BigInt -> new(5)), "",
   "Math::BigInt -> blt(7, Math::BigInt -> new(5))");

note("blt() as an instance method");

is(Math::BigInt -> new(5) -> blt(7), 1,
   "Math::BigInt -> new(5) -> blt(7)");

is(Math::BigInt -> new(5) -> blt(5), "",
   "Math::BigInt -> new(5) -> blt(5)");

is(Math::BigInt -> new(7) -> blt(5), "",
   "Math::BigInt -> new(7) -> blt(5)");

is(Math::BigInt -> new(5) -> blt(Math::BigInt -> new(7)), 1,
   "Math::BigInt -> new(5) -> blt(Math::BigInt -> new(7))");

is(Math::BigInt -> new(5) -> blt(Math::BigInt -> new(5)), "",
   "Math::BigInt -> new(5) -> blt(Math::BigInt -> new(5))");

is(Math::BigInt -> new(7) -> blt(Math::BigInt -> new(5)), "",
   "Math::BigInt -> new(7) -> blt(Math::BigInt -> new(5))");
