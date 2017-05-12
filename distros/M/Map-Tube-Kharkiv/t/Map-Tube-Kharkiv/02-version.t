# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Kharkiv;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Kharkiv::VERSION, 0.05, 'Version.');
