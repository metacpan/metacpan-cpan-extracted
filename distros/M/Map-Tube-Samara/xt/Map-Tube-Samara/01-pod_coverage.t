use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Map::Tube::Samara', 'Map::Tube::Samara is covered.');
