use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('File::Find::Rule::DMIDecode', 'File::Find::Rule::DMIDecode is covered.');
