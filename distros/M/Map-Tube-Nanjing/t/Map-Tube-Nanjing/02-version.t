# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Nanjing;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Nanjing::VERSION, 0.04, 'Version.');
