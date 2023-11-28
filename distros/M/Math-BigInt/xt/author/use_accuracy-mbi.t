# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2;

use Math::BigInt accuracy => 42;

is(Math::BigInt -> accuracy(), 42,
   'Math::BigInt -> accuracy() is 42');

is(Math::BigInt -> config("accuracy"), 42,
   'Math::BigInt -> config("accuracy") is 42');
