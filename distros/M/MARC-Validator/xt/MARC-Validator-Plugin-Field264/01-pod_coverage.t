use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('MARC::Validator::Plugin::Field264', 'MARC::Validator::Plugin::Field264 is covered.');
