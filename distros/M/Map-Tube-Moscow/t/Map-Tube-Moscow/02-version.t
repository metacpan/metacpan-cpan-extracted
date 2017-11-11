# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Moscow;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Moscow::VERSION, 0.08, 'Version.');
