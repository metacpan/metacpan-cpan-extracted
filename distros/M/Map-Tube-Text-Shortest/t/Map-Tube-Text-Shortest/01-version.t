# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Text::Shortest;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Text::Shortest::VERSION, 0.01, 'Version.');
