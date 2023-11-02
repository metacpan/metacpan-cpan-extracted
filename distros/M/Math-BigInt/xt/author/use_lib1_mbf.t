# -*- mode: perl; -*-

# See if using Math::BigInt, Math::BigFloat, and Math::BigRat works together
# nicely. All t/use_lib*.t should be equivalent.

use strict;
use warnings;
use lib 't';

use Test::More tests => 2;

use Math::BigFloat lib => 'BareCalc';           # loads "BareCalc"

is(Math::BigInt -> config('lib'), 'Math::BigInt::BareCalc',
   "Math::BigInt -> config('lib')");

is(Math::BigFloat -> new(123) -> badd(123), 246,
   'Math::BigFloat -> new(123) -> badd(123)');
