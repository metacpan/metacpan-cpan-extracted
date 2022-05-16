# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 18;

use Math::BigFloat;

note("blt() as a class method");

is(Math::BigFloat -> blt(5, 7), 1,
   "Math::BigFloat -> blt(5, 7)");

is(Math::BigFloat -> blt(5, 5), "",
   "Math::BigFloat -> blt(5, 5)");

is(Math::BigFloat -> blt(7, 5), "",
   "Math::BigFloat -> blt(7, 5)");

is(Math::BigFloat -> blt(Math::BigFloat -> new(5), 7), 1,
   "Math::BigFloat -> blt(Math::BigFloat -> new(5), 7)");

is(Math::BigFloat -> blt(Math::BigFloat -> new(5), 5), "",
   "Math::BigFloat -> blt(Math::BigFloat -> new(5), 5)");

is(Math::BigFloat -> blt(Math::BigFloat -> new(7), 5), "",
   "Math::BigFloat -> blt(Math::BigFloat -> new(7), 5)");

is(Math::BigFloat -> blt(5, Math::BigFloat -> new(7)), 1,
   "Math::BigFloat -> blt(5, Math::BigFloat -> new(7))");

is(Math::BigFloat -> blt(5, Math::BigFloat -> new(5)), "",
   "Math::BigFloat -> blt(5, Math::BigFloat -> new(5))");

is(Math::BigFloat -> blt(7, Math::BigFloat -> new(5)), "",
   "Math::BigFloat -> blt(7, Math::BigFloat -> new(5))");

is(Math::BigFloat -> blt(Math::BigFloat -> new(5), Math::BigFloat -> new(7)), 1,
   "Math::BigFloat -> blt(5, Math::BigFloat -> new(7))");

is(Math::BigFloat -> blt(Math::BigFloat -> new(5), Math::BigFloat -> new(5)), "",
   "Math::BigFloat -> blt(Math::BigFloat -> new(5), Math::BigFloat -> new(5))");

is(Math::BigFloat -> blt(Math::BigFloat -> new(7), Math::BigFloat -> new(5)), "",
   "Math::BigFloat -> blt(7, Math::BigFloat -> new(5))");

note("blt() as an instance method");

is(Math::BigFloat -> new(5) -> blt(7), 1,
   "Math::BigFloat -> new(5) -> blt(7)");

is(Math::BigFloat -> new(5) -> blt(5), "",
   "Math::BigFloat -> new(5) -> blt(5)");

is(Math::BigFloat -> new(7) -> blt(5), "",
   "Math::BigFloat -> new(7) -> blt(5)");

is(Math::BigFloat -> new(5) -> blt(Math::BigFloat -> new(7)), 1,
   "Math::BigFloat -> new(5) -> blt(Math::BigFloat -> new(7))");

is(Math::BigFloat -> new(5) -> blt(Math::BigFloat -> new(5)), "",
   "Math::BigFloat -> new(5) -> blt(Math::BigFloat -> new(5))");

is(Math::BigFloat -> new(7) -> blt(Math::BigFloat -> new(5)), "",
   "Math::BigFloat -> new(7) -> blt(Math::BigFloat -> new(5))");
