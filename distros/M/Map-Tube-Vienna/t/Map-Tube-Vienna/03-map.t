# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Vienna;
use Test::Map::Tube 'tests' => 2;
use Test::NoWarnings;

# Test.
ok_map(Map::Tube::Vienna->new, 'Test validity of map.');
