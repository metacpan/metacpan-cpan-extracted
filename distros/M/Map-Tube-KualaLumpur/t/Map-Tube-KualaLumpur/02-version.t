use strict;
use warnings;

use Map::Tube::KualaLumpur;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::KualaLumpur::VERSION, 0.07, 'Version.');
