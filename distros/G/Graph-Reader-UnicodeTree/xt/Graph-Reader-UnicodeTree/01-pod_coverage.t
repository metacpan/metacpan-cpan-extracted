use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Graph::Reader::UnicodeTree', 'Graph::Reader::UnicodeTree is covered.');
