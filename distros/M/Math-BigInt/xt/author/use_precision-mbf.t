# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2;

use Math::BigFloat precision => 42;

is(Math::BigFloat -> precision(), 42,
   'Math::BigFloat -> precision() is 42');

is(Math::BigFloat -> config("precision"), 42,
   'Math::BigFloat -> config("precision") is 42');
