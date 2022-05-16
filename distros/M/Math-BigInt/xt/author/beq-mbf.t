# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 12;

use Math::BigFloat;

note("beq() as a class method");

is(Math::BigFloat -> beq(5, 5), 1,
   "Math::BigFloat -> beq(5, 5)");

is(Math::BigFloat -> beq(5, 7), "",
   "Math::BigFloat -> beq(5, 7)");

is(Math::BigFloat -> beq(Math::BigFloat -> new(5), 5), 1,
   "Math::BigFloat -> beq(Math::BigFloat -> new(5), 5)");

is(Math::BigFloat -> beq(Math::BigFloat -> new(5), 7), "",
   "Math::BigFloat -> beq(Math::BigFloat -> new(5), 7)");

is(Math::BigFloat -> beq(5, Math::BigFloat -> new(5)), 1,
   "Math::BigFloat -> beq(5, Math::BigFloat -> new(5))");

is(Math::BigFloat -> beq(5, Math::BigFloat -> new(7)), "",
   "Math::BigFloat -> beq(5, Math::BigFloat -> new(7))");

is(Math::BigFloat -> beq(Math::BigFloat -> new(5), Math::BigFloat -> new(5)), 1,
   "Math::BigFloat -> beq(Math::BigFloat -> new(5), Math::BigFloat -> new(5))");

is(Math::BigFloat -> beq(Math::BigFloat -> new(5), Math::BigFloat -> new(7)), "",
   "Math::BigFloat -> beq(5, Math::BigFloat -> new(7))");

note("beq() as an instance method");

is(Math::BigFloat -> new(5) -> beq(5), 1,
   "Math::BigFloat -> new(5) -> beq(5)");

is(Math::BigFloat -> new(5) -> beq(7), "",
   "Math::BigFloat -> new(5) -> beq(7)");

is(Math::BigFloat -> new(5) -> beq(Math::BigFloat -> new(5)), 1,
   "Math::BigFloat -> new(5) -> beq(Math::BigFloat -> new(5))");

is(Math::BigFloat -> new(5) -> beq(Math::BigFloat -> new(7)), "",
   "Math::BigFloat -> new(5) -> beq(Math::BigFloat -> new(7))");
