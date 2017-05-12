# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Prague;
use Test::Map::Tube 'tests' => 2;
use Test::NoWarnings;

# Test.
ok_map(Map::Tube::Prague->new, 'Test validity of map.');
