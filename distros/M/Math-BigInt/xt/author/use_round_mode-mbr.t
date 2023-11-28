# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2;

use Math::BigRat round_mode => "odd";

is(Math::BigRat -> round_mode(), "odd",
   'Math::BigRat -> round_mode() is "odd"');

is(Math::BigRat -> config("round_mode"), "odd",
   'Math::BigRat -> config("round_mode") is "odd"');
