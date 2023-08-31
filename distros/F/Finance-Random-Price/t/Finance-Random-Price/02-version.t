use strict;
use warnings;

use Finance::Random::Price;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Finance::Random::Price::VERSION, 0.01, 'Version.');
