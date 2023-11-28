use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Graph::Reader::TGF::CSV', 'Graph::Reader::TGF::CSV is covered.');
