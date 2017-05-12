use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Error::Pure::ANSIColor::Error', 'Error::Pure::ANSIColor::Error is covered.');
