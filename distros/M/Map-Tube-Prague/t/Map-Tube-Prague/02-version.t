# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Prague;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Prague::VERSION, 0.13, 'Version.');
