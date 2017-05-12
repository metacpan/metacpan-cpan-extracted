# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::KualaLumpur;
use Test::Map::Tube 'tests' => 2;
use Test::NoWarnings;

# Test.
ok_map(Map::Tube::KualaLumpur->new, 'Test validity of map.');
