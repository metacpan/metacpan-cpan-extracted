# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Kazan;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Kazan::VERSION, 0.05, 'Version.');
