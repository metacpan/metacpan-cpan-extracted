use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Fedora::RPM::Spec::License', 'Fedora::RPM::Spec::License is covered.');
