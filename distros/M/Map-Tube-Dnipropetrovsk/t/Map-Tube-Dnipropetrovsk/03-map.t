# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Dnipropetrovsk;
use Test::Map::Tube 'tests' => 2;
use Test::NoWarnings;

# Test.
ok_map(Map::Tube::Dnipropetrovsk->new, 'Test validity of map.');
