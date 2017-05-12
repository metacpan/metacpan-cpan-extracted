# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Dnipropetrovsk;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Dnipropetrovsk::VERSION, 0.05, 'Version.');
