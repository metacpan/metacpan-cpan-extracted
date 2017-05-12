# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Sofia;
use Test::Map::Tube 'tests' => 2;
use Test::NoWarnings;

# Test.
ok_map(Map::Tube::Sofia->new, 'Test validity of map.');
