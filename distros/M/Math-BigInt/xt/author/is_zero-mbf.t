# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 6;

use Math::BigFloat;

note("is_zero() as a class method");

is(Math::BigFloat -> is_zero(0), 1,
   "Math::BigFloat -> is_zero(0)");

is(Math::BigFloat -> is_zero(1), 0,
   "Math::BigFloat -> is_zero(1)");

is(Math::BigFloat -> is_zero(Math::BigFloat -> bzero()), 1,
   "Math::BigFloat -> is_zero(Math::BigFloat -> bzero())");

is(Math::BigFloat -> is_zero(Math::BigFloat -> bone()), 0,
   "Math::BigFloat -> is_zero(Math::BigFloat -> bone())");

note("is_zero() as an instance method");

is(Math::BigFloat -> bzero() -> is_zero(), 1,
   "Math::BigFloat -> bzero() -> is_zero()");

is(Math::BigFloat -> bone() -> is_zero(), 0,
   "Math::BigFloat -> bone() -> is_zero()");
