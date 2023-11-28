# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2;

use Math::BigFloat accuracy => 42;

is(Math::BigFloat -> accuracy(), 42,
   'Math::BigFloat -> accuracy() is 42');

is(Math::BigFloat -> config("accuracy"), 42,
   'Math::BigFloat -> config("accuracy") is 42');
