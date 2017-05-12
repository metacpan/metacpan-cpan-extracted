# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Moscow;
use Test::Map::Tube 'tests' => 2;
use Test::NoWarnings;

# Test.
ok_map(Map::Tube::Moscow->new, 'Test validity of map.');
