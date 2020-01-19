use strict;
use warnings;

use Map::Tube::Budapest;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Budapest::VERSION, 0.05, 'Version.');
