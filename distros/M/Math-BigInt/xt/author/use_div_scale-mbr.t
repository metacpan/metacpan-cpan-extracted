# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2;

use Math::BigRat div_scale => 42;

is(Math::BigRat -> div_scale(), 42,
   'Math::BigRat -> div_scale() is 42');

is(Math::BigRat -> config("div_scale"), 42,
   'Math::BigRat -> config("div_scale") is 42');
