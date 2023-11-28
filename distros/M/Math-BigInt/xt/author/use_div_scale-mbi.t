# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2;

use Math::BigInt div_scale => 42;

is(Math::BigInt -> div_scale(), 42,
   'Math::BigInt -> div_scale() is 42');

is(Math::BigInt -> config("div_scale"), 42,
   'Math::BigInt -> config("div_scale") is 42');
