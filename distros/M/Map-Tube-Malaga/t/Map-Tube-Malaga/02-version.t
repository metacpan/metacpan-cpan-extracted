# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Malaga;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Malaga::VERSION, 0.15, 'Version.');
