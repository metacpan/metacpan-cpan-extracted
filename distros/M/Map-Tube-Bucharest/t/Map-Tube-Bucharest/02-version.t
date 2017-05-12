# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Bucharest;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Bucharest::VERSION, 0.08, 'Version.');
