# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 18;

use Math::BigFloat;

note("ble() as a class method");

is(Math::BigFloat -> ble(5, 7), 1,
   "Math::BigFloat -> ble(5, 7)");

is(Math::BigFloat -> ble(5, 5), 1,
   "Math::BigFloat -> ble(5, 5)");

is(Math::BigFloat -> ble(7, 5), "",
   "Math::BigFloat -> ble(7, 5)");

is(Math::BigFloat -> ble(Math::BigFloat -> new(5), 7), 1,
   "Math::BigFloat -> ble(Math::BigFloat -> new(5), 7)");

is(Math::BigFloat -> ble(Math::BigFloat -> new(5), 5), 1,
   "Math::BigFloat -> ble(Math::BigFloat -> new(5), 5)");

is(Math::BigFloat -> ble(Math::BigFloat -> new(7), 5), "",
   "Math::BigFloat -> ble(Math::BigFloat -> new(7), 5)");

is(Math::BigFloat -> ble(5, Math::BigFloat -> new(7)), 1,
   "Math::BigFloat -> ble(5, Math::BigFloat -> new(7))");

is(Math::BigFloat -> ble(5, Math::BigFloat -> new(5)), 1,
   "Math::BigFloat -> ble(5, Math::BigFloat -> new(5))");

is(Math::BigFloat -> ble(7, Math::BigFloat -> new(5)), "",
   "Math::BigFloat -> ble(7, Math::BigFloat -> new(5))");

is(Math::BigFloat -> ble(Math::BigFloat -> new(5), Math::BigFloat -> new(7)), 1,
   "Math::BigFloat -> ble(5, Math::BigFloat -> new(7))");

is(Math::BigFloat -> ble(Math::BigFloat -> new(5), Math::BigFloat -> new(5)), 1,
   "Math::BigFloat -> ble(Math::BigFloat -> new(5), Math::BigFloat -> new(5))");

is(Math::BigFloat -> ble(Math::BigFloat -> new(7), Math::BigFloat -> new(5)), "",
   "Math::BigFloat -> ble(7, Math::BigFloat -> new(5))");

note("ble() as an instance method");

is(Math::BigFloat -> new(5) -> ble(7), 1,
   "Math::BigFloat -> new(5) -> ble(7)");

is(Math::BigFloat -> new(5) -> ble(5), 1,
   "Math::BigFloat -> new(5) -> ble(5)");

is(Math::BigFloat -> new(7) -> ble(5), "",
   "Math::BigFloat -> new(7) -> ble(5)");

is(Math::BigFloat -> new(5) -> ble(Math::BigFloat -> new(7)), 1,
   "Math::BigFloat -> new(5) -> ble(Math::BigFloat -> new(7))");

is(Math::BigFloat -> new(5) -> ble(Math::BigFloat -> new(5)), 1,
   "Math::BigFloat -> new(5) -> ble(Math::BigFloat -> new(5))");

is(Math::BigFloat -> new(7) -> ble(Math::BigFloat -> new(5)), "",
   "Math::BigFloat -> new(7) -> ble(Math::BigFloat -> new(5))");
