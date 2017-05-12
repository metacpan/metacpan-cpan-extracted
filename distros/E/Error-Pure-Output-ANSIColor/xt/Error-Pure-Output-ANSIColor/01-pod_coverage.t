use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Error::Pure::Output::ANSIColor', 'Error::Pure::Output::ANSIColor is covered.');
