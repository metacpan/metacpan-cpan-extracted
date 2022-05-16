# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 24;

use Math::BigInt;

note("bdec() as a class method");

is(Math::BigInt -> bdec(-2), -3,
   'Math::BigInt -> bdec(-2)');
is(Math::BigInt -> bdec(-1), -2,
   'Math::BigInt -> bdec(-1)');
is(Math::BigInt -> bdec(0), -1,
   'Math::BigInt -> bdec(0)');
is(Math::BigInt -> bdec(1), 0,
   'Math::BigInt -> bdec(1)');
is(Math::BigInt -> bdec(2), 1,
   'Math::BigInt -> bdec(2)');
is(Math::BigInt -> bdec("-inf"), "-inf",
   'Math::BigInt -> bdec("-inf")');
is(Math::BigInt -> bdec("inf"), "inf",
   'Math::BigInt -> bdec("inf")');
is(Math::BigInt -> bdec("NaN"), "NaN",
   'Math::BigInt -> bdec("NaN")');

note("bdec() as an instance method");

is(Math::BigInt -> new(-2) -> bdec(), -3,
   'Math::BigInt -> new(-2) -> bdec()');
is(Math::BigInt -> new(-1) -> bdec(), -2,
   'Math::BigInt -> new(-1) -> bdec()');
is(Math::BigInt -> new(0) -> bdec(), -1,
   'Math::BigInt -> new(0) -> bdec()');
is(Math::BigInt -> new(1) -> bdec(), 0,
   'Math::BigInt -> new(1) -> bdec()');
is(Math::BigInt -> new(2) -> bdec(), 1,
   'Math::BigInt -> new(2) -> bdec()');
is(Math::BigInt -> new("-inf") -> bdec(), "-inf",
   'Math::BigInt -> new("-inf") -> bdec()');
is(Math::BigInt -> new("inf") -> bdec(), "inf",
   'Math::BigInt -> new("inf") -> bdec()');
is(Math::BigInt -> new("NaN") -> bdec(), "NaN",
   'Math::BigInt -> new("NaN") -> bdec()');

note("bdec() as a function");

is(Math::BigInt::bdec(-2), -3,
   'Math::BigInt::bdec(-2)');
is(Math::BigInt::bdec(-1), -2,
   'Math::BigInt::bdec(-1)');
is(Math::BigInt::bdec(0), -1,
   'Math::BigInt::bdec(0)');
is(Math::BigInt::bdec(1), 0,
   'Math::BigInt::bdec(1)');
is(Math::BigInt::bdec(2), 1,
   'Math::BigInt::bdec(2)');
is(Math::BigInt::bdec("-inf"), "-inf",
   'Math::BigInt::bdec("-inf")');
is(Math::BigInt::bdec("inf"), "inf",
   'Math::BigInt::bdec("inf")');
is(Math::BigInt::bdec("NaN"), "NaN",
   'Math::BigInt::bdec("NaN")');
