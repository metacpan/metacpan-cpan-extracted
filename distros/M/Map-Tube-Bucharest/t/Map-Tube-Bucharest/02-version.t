use strict;
use warnings;

use Map::Tube::Bucharest;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Bucharest::VERSION, 0.11, 'Version.');
