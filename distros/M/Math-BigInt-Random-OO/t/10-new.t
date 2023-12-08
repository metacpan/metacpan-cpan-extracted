# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 4;

use Math::BigInt::Random::OO;

# Create constructor objects with various arguments.

new_ok('Math::BigInt::Random::OO', [min => 0, max => 1]);
new_ok('Math::BigInt::Random::OO', [length => 3, base => 8]);
new_ok('Math::BigInt::Random::OO', [length_bin => 4]);
new_ok('Math::BigInt::Random::OO', [length_hex => 5]);
