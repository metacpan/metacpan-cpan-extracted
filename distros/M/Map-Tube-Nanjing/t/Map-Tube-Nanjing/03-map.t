use strict;
use warnings;

use Map::Tube::Nanjing;
use Test::Map::Tube 'tests' => 2;
use Test::NoWarnings;

# Test.
ok_map(Map::Tube::Nanjing->new, 'Test validity of map.');
