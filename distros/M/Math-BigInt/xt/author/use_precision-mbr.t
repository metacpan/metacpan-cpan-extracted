# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2;

use Math::BigRat precision => 42;

is(Math::BigRat -> precision(), 42,
   'Math::BigRat -> precision() is 42');

is(Math::BigRat -> config("precision"), 42,
   'Math::BigRat -> config("precision") is 42');
