use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('MARC::Leader::L10N::en', 'MARC::Leader::L10N::en is covered.');
