# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Tbilisi;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Tbilisi::VERSION, 0.04, 'Version.');
