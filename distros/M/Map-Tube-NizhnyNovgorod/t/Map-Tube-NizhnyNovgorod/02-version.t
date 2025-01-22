use strict;
use warnings;

use Map::Tube::NizhnyNovgorod;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::NizhnyNovgorod::VERSION, 0.04, 'Version.');
