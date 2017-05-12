# Pragmas.
use strict;
use warnings;

# Modules.
use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Error::Pure::Output::Tags::HTMLCustomPage', 'Error::Pure::Output::Tags::HTMLCustomPage is covered.');
