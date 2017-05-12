# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Singapore;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Singapore::VERSION, 0.03, 'Version.');
