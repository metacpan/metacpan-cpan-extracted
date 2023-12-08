use strict;
use warnings;

use Map::Tube::Kazan;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Kazan::VERSION, 0.07, 'Version.');
