# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 24;

use Math::BigFloat;

note("bdec() as a class method");

is(Math::BigFloat -> bdec(-2), -3,
   'Math::BigFloat -> bdec(-2)');
is(Math::BigFloat -> bdec(-1), -2,
   'Math::BigFloat -> bdec(-1)');
is(Math::BigFloat -> bdec(0), -1,
   'Math::BigFloat -> bdec(0)');
is(Math::BigFloat -> bdec(1), 0,
   'Math::BigFloat -> bdec(1)');
is(Math::BigFloat -> bdec(2), 1,
   'Math::BigFloat -> bdec(2)');
is(Math::BigFloat -> bdec("-inf"), "-inf",
   'Math::BigFloat -> bdec("-inf")');
is(Math::BigFloat -> bdec("inf"), "inf",
   'Math::BigFloat -> bdec("inf")');
is(Math::BigFloat -> bdec("NaN"), "NaN",
   'Math::BigFloat -> bdec("NaN")');

note("bdec() as an instance method");

is(Math::BigFloat -> new(-2) -> bdec(), -3,
   'Math::BigFloat -> new(-2) -> bdec()');
is(Math::BigFloat -> new(-1) -> bdec(), -2,
   'Math::BigFloat -> new(-1) -> bdec()');
is(Math::BigFloat -> new(0) -> bdec(), -1,
   'Math::BigFloat -> new(0) -> bdec()');
is(Math::BigFloat -> new(1) -> bdec(), 0,
   'Math::BigFloat -> new(1) -> bdec()');
is(Math::BigFloat -> new(2) -> bdec(), 1,
   'Math::BigFloat -> new(2) -> bdec()');
is(Math::BigFloat -> new("-inf") -> bdec(), "-inf",
   'Math::BigFloat -> new("-inf") -> bdec()');
is(Math::BigFloat -> new("inf") -> bdec(), "inf",
   'Math::BigFloat -> new("inf") -> bdec()');
is(Math::BigFloat -> new("NaN") -> bdec(), "NaN",
   'Math::BigFloat -> new("NaN") -> bdec()');

note("bdec() as a function");

SKIP: {
    skip "Math::BigInt doesn't support binc() as a function", 8;

    is(Math::BigFloat::bdec(-2), -3,
       'Math::BigFloat::bdec(-2)');
    is(Math::BigFloat::bdec(-1), -2,
       'Math::BigFloat::bdec(-1)');
    is(Math::BigFloat::bdec(0), -1,
       'Math::BigFloat::bdec(0)');
    is(Math::BigFloat::bdec(1), 0,
       'Math::BigFloat::bdec(1)');
    is(Math::BigFloat::bdec(2), 1,
       'Math::BigFloat::bdec(2)');
    is(Math::BigFloat::bdec("-inf"), "-inf",
       'Math::BigFloat::bdec("-inf")');
    is(Math::BigFloat::bdec("inf"), "inf",
       'Math::BigFloat::bdec("inf")');
    is(Math::BigFloat::bdec("NaN"), "NaN",
       'Math::BigFloat::bdec("NaN")');
}
