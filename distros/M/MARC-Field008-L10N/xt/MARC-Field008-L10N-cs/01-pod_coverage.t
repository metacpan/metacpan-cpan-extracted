use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('MARC::Field008::L10N::cs', 'MARC::Field008::L10N::cs is covered.');
