# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Minsk;
use Test::Map::Tube 'tests' => 2;
use Test::NoWarnings;

# Test.
ok_map(Map::Tube::Minsk->new, 'Test validity of map.');
