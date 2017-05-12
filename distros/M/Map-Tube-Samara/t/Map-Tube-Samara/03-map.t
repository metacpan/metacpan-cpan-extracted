# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Samara;
use Test::Map::Tube 'tests' => 2;
use Test::NoWarnings;

# Test.
ok_map(Map::Tube::Samara->new, 'Test validity of map.');
