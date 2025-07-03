use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('MARC::Validator::Plugin::Field008', 'MARC::Validator::Plugin::Field008 is covered.');
