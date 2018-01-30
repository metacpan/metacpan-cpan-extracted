use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Error::Pure::HTTP::Print', 'Error::Pure::HTTP::Print is covered.');
