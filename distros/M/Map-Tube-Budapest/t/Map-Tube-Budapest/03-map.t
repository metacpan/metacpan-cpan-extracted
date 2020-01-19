use strict;
use warnings;

use Map::Tube::Budapest;
use Test::Map::Tube 'tests' => 2;
use Test::NoWarnings;

# Test.
ok_map(Map::Tube::Budapest->new, 'Test validity of map.');
