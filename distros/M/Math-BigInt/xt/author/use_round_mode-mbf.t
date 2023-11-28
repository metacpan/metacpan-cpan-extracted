# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2;

use Math::BigFloat round_mode => "odd";

is(Math::BigFloat -> round_mode(), "odd",
   'Math::BigFloat -> round_mode() is "odd"');

is(Math::BigFloat -> config("round_mode"), "odd",
   'Math::BigFloat -> config("round_mode") is "odd"');
