# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Kharkiv;
use Test::Map::Tube 'tests' => 2;
use Test::NoWarnings;

# Test.
ok_map(Map::Tube::Kharkiv->new, 'Test validity of map.');
