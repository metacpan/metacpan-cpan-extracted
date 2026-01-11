use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('MARC::Validator::Filter::Plugin::Material', 'MARC::Validator::Filter::Plugin::Material is covered.');
