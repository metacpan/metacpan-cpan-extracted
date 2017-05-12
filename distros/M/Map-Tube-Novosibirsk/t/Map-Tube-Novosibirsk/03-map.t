# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Novosibirsk;
use Test::Map::Tube 'tests' => 2;
use Test::NoWarnings;

# Test.
ok_map(Map::Tube::Novosibirsk->new, 'Test validity of map.');
