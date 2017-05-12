# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::GraphViz::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::GraphViz::Utils::VERSION, 0.06, 'Version.');
