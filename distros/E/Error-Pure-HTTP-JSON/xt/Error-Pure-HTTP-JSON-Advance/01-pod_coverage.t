use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Error::Pure::HTTP::JSON::Advance', 'Error::Pure::HTTP::JSON::Advance is covered.');
