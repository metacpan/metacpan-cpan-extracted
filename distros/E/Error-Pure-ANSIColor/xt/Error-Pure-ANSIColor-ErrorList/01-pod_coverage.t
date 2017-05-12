use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Error::Pure::ANSIColor::ErrorList', 'Error::Pure::ANSIColor::ErrorList is covered.');
