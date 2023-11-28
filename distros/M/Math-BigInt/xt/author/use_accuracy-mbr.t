# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2;

use Math::BigRat accuracy => 42;

is(Math::BigRat -> accuracy(), 42,
   'Math::BigRat -> accuracy() is 42');

is(Math::BigRat -> config("accuracy"), 42,
   'Math::BigRat -> config("accuracy") is 42');
