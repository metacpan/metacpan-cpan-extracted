# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 24;

use Math::BigInt;

note("binc() as a class method");

is(Math::BigInt -> binc(-2), -1,
   'Math::BigInt -> binc(-2)');
is(Math::BigInt -> binc(-1), 0,
   'Math::BigInt -> binc(-1)');
is(Math::BigInt -> binc(0), 1,
   'Math::BigInt -> binc(0)');
is(Math::BigInt -> binc(1), 2,
   'Math::BigInt -> binc(1)');
is(Math::BigInt -> binc(2), 3,
   'Math::BigInt -> binc(2)');
is(Math::BigInt -> binc("-inf"), "-inf",
   'Math::BigInt -> binc("-inf")');
is(Math::BigInt -> binc("inf"), "inf",
   'Math::BigInt -> binc("inf")');
is(Math::BigInt -> binc("NaN"), "NaN",
   'Math::BigInt -> binc("NaN")');

note("binc() as an instance method");

is(Math::BigInt -> new(-2) -> binc(), -1,
   'Math::BigInt -> new(-2) -> binc()');
is(Math::BigInt -> new(-1) -> binc(), 0,
   'Math::BigInt -> new(-1) -> binc()');
is(Math::BigInt -> new(0) -> binc(), 1,
   'Math::BigInt -> new(0) -> binc()');
is(Math::BigInt -> new(1) -> binc(), 2,
   'Math::BigInt -> new(1) -> binc()');
is(Math::BigInt -> new(2) -> binc(), 3,
   'Math::BigInt -> new(2) -> binc()');
is(Math::BigInt -> new("-inf") -> binc(), "-inf",
   'Math::BigInt -> new("-inf") -> binc()');
is(Math::BigInt -> new("inf") -> binc(), "inf",
   'Math::BigInt -> new("inf") -> binc()');
is(Math::BigInt -> new("NaN") -> binc(), "NaN",
   'Math::BigInt -> new("NaN") -> binc()');

note("binc() as a function");

is(Math::BigInt::binc(-2), -1,
   'Math::BigInt::binc(-2)');
is(Math::BigInt::binc(-1), 0,
   'Math::BigInt::binc(-1)');
is(Math::BigInt::binc(0), 1,
   'Math::BigInt::binc(0)');
is(Math::BigInt::binc(1), 2,
   'Math::BigInt::binc(1)');
is(Math::BigInt::binc(2), 3,
   'Math::BigInt::binc(2)');
is(Math::BigInt::binc("-inf"), "-inf",
   'Math::BigInt::binc("-inf")');
is(Math::BigInt::binc("inf"), "inf",
   'Math::BigInt::binc("inf")');
is(Math::BigInt::binc("NaN"), "NaN",
   'Math::BigInt::binc("NaN")');
