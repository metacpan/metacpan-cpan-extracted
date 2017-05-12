# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Graph;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Graph::VERSION, 0.05, 'Version.');
