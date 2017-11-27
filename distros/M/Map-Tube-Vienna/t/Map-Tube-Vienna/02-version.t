# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Vienna;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Vienna::VERSION, 0.08, 'Version.');
