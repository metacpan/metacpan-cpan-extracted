# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::KualaLumpur;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::KualaLumpur::VERSION, 0.05, 'Version.');
