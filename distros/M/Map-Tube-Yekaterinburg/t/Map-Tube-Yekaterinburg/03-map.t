# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Yekaterinburg;
use Test::Map::Tube 'tests' => 2;
use Test::NoWarnings;

# Test.
ok_map(Map::Tube::Yekaterinburg->new, 'Test validity of map.');
