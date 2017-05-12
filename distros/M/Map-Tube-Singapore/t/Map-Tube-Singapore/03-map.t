# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Singapore;
use Test::Map::Tube 'tests' => 2;
use Test::NoWarnings;

# Test.
ok_map(Map::Tube::Singapore->new, 'Test validity of map.');
