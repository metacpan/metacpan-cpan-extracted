# -*- mode: perl; -*-

# see if using Math::BigInt and Math::BigRat works together nicely.
# all use_lib*.t should be equivalent.

use strict;
use warnings;
use lib 't';

use Test::More tests => 2;

use Math::BigRat lib => 'BareCalc';             # loads "BareCalc"

is(Math::BigInt -> config('lib'), 'Math::BigInt::BareCalc',
   "Math::BigInt -> config('lib')");

is(Math::BigRat -> new(123) -> badd(123), 246,
   'Math::BigRat -> new(123) -> badd(123)');
