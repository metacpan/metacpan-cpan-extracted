# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Samara;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Samara::VERSION, 0.07, 'Version.');
