# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2;

use Math::BigFloat div_scale => 42;

is(Math::BigFloat -> div_scale(), 42,
   'Math::BigFloat -> div_scale() is 42');

is(Math::BigFloat -> config("div_scale"), 42,
   'Math::BigFloat -> config("div_scale") is 42');
