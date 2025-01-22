use strict;
use warnings;

use Map::Tube::NizhnyNovgorod;
use Test::Map::Tube 'tests' => 2;
use Test::NoWarnings;

# Test.
ok_map(Map::Tube::NizhnyNovgorod->new, 'Test validity of map.');
