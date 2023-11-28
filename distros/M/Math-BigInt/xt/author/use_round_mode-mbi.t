# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2;

use Math::BigInt round_mode => "odd";

is(Math::BigInt -> round_mode(), "odd",
   'Math::BigInt -> round_mode() is "odd"');

is(Math::BigInt -> config("round_mode"), "odd",
   'Math::BigInt -> config("round_mode") is "odd"');
