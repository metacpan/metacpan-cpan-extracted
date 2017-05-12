# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Tbilisi;
use Test::Map::Tube 'tests' => 2;
use Test::NoWarnings;

# Test.
ok_map(Map::Tube::Tbilisi->new, 'Test validity of map.');
