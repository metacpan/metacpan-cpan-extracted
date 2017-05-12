# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::NizhnyNovgorod;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::NizhnyNovgorod::VERSION, 0.03, 'Version.');
