# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 24;

use Math::BigFloat;

note("binc() as a class method");

is(Math::BigFloat -> binc(-2), -1,
   'Math::BigFloat -> binc(-2)');
is(Math::BigFloat -> binc(-1), 0,
   'Math::BigFloat -> binc(-1)');
is(Math::BigFloat -> binc(0), 1,
   'Math::BigFloat -> binc(0)');
is(Math::BigFloat -> binc(1), 2,
   'Math::BigFloat -> binc(1)');
is(Math::BigFloat -> binc(2), 3,
   'Math::BigFloat -> binc(2)');
is(Math::BigFloat -> binc("-inf"), "-inf",
   'Math::BigFloat -> binc("-inf")');
is(Math::BigFloat -> binc("inf"), "inf",
   'Math::BigFloat -> binc("inf")');
is(Math::BigFloat -> binc("NaN"), "NaN",
   'Math::BigFloat -> binc("NaN")');

note("binc() as an instance method");

is(Math::BigFloat -> new(-2) -> binc(), -1,
   'Math::BigFloat -> new(-2) -> binc()');
is(Math::BigFloat -> new(-1) -> binc(), 0,
   'Math::BigFloat -> new(-1) -> binc()');
is(Math::BigFloat -> new(0) -> binc(), 1,
   'Math::BigFloat -> new(0) -> binc()');
is(Math::BigFloat -> new(1) -> binc(), 2,
   'Math::BigFloat -> new(1) -> binc()');
is(Math::BigFloat -> new(2) -> binc(), 3,
   'Math::BigFloat -> new(2) -> binc()');
is(Math::BigFloat -> new("-inf") -> binc(), "-inf",
   'Math::BigFloat -> new("-inf") -> binc()');
is(Math::BigFloat -> new("inf") -> binc(), "inf",
   'Math::BigFloat -> new("inf") -> binc()');
is(Math::BigFloat -> new("NaN") -> binc(), "NaN",
   'Math::BigFloat -> new("NaN") -> binc()');

note("binc() as a function");

SKIP: {
    skip "Math::BigInt doesn't support binc() as a function", 8;

    is(Math::BigFloat::binc(-2), -1,
       'Math::BigFloat::binc(-2)');
    is(Math::BigFloat::binc(-1), 0,
       'Math::BigFloat::binc(-1)');
    is(Math::BigFloat::binc(0), 1,
       'Math::BigFloat::binc(0)');
    is(Math::BigFloat::binc(1), 2,
       'Math::BigFloat::binc(1)');
    is(Math::BigFloat::binc(2), 3,
       'Math::BigFloat::binc(2)');
    is(Math::BigFloat::binc("-inf"), "-inf",
       'Math::BigFloat::binc("-inf")');
    is(Math::BigFloat::binc("inf"), "inf",
       'Math::BigFloat::binc("inf")');
    is(Math::BigFloat::binc("NaN"), "NaN",
       'Math::BigFloat::binc("NaN")');
}
