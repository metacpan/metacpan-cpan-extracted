# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Malaga;
use Test::Map::Tube 'tests' => 2;
use Test::NoWarnings;

# Test.
ok_map(Map::Tube::Malaga->new, 'Test validity of map.');
