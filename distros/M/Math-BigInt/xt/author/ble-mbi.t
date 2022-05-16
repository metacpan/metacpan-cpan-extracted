# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 18;

use Math::BigInt;

note("ble() as a class method");

is(Math::BigInt -> ble(5, 7), 1,
   "Math::BigInt -> ble(5, 7)");

is(Math::BigInt -> ble(5, 5), 1,
   "Math::BigInt -> ble(5, 5)");

is(Math::BigInt -> ble(7, 5), "",
   "Math::BigInt -> ble(7, 5)");

is(Math::BigInt -> ble(Math::BigInt -> new(5), 7), 1,
   "Math::BigInt -> ble(Math::BigInt -> new(5), 7)");

is(Math::BigInt -> ble(Math::BigInt -> new(5), 5), 1,
   "Math::BigInt -> ble(Math::BigInt -> new(5), 5)");

is(Math::BigInt -> ble(Math::BigInt -> new(7), 5), "",
   "Math::BigInt -> ble(Math::BigInt -> new(7), 5)");

is(Math::BigInt -> ble(5, Math::BigInt -> new(7)), 1,
   "Math::BigInt -> ble(5, Math::BigInt -> new(7))");

is(Math::BigInt -> ble(5, Math::BigInt -> new(5)), 1,
   "Math::BigInt -> ble(5, Math::BigInt -> new(5))");

is(Math::BigInt -> ble(7, Math::BigInt -> new(5)), "",
   "Math::BigInt -> ble(7, Math::BigInt -> new(5))");

is(Math::BigInt -> ble(Math::BigInt -> new(5), Math::BigInt -> new(7)), 1,
   "Math::BigInt -> ble(5, Math::BigInt -> new(7))");

is(Math::BigInt -> ble(Math::BigInt -> new(5), Math::BigInt -> new(5)), 1,
   "Math::BigInt -> ble(Math::BigInt -> new(5), Math::BigInt -> new(5))");

is(Math::BigInt -> ble(Math::BigInt -> new(7), Math::BigInt -> new(5)), "",
   "Math::BigInt -> ble(7, Math::BigInt -> new(5))");

note("ble() as an instance method");

is(Math::BigInt -> new(5) -> ble(7), 1,
   "Math::BigInt -> new(5) -> ble(7)");

is(Math::BigInt -> new(5) -> ble(5), 1,
   "Math::BigInt -> new(5) -> ble(5)");

is(Math::BigInt -> new(7) -> ble(5), "",
   "Math::BigInt -> new(7) -> ble(5)");

is(Math::BigInt -> new(5) -> ble(Math::BigInt -> new(7)), 1,
   "Math::BigInt -> new(5) -> ble(Math::BigInt -> new(7))");

is(Math::BigInt -> new(5) -> ble(Math::BigInt -> new(5)), 1,
   "Math::BigInt -> new(5) -> ble(Math::BigInt -> new(5))");

is(Math::BigInt -> new(7) -> ble(Math::BigInt -> new(5)), "",
   "Math::BigInt -> new(7) -> ble(Math::BigInt -> new(5))");
