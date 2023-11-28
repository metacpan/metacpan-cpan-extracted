# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2;

use Math::BigInt precision => 42;

is(Math::BigInt -> precision(), 42,
   'Math::BigInt -> precision() is 42');

is(Math::BigInt -> config("precision"), 42,
   'Math::BigInt -> config("precision") is 42');
