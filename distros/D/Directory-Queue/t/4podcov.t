#!perl

use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
eval("use Test::Pod::Coverage 1.08");
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage" if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
eval("use Pod::Coverage 0.18");
plan skip_all => "Pod::Coverage 0.18 required for testing POD coverage" if $@;

all_pod_coverage_ok();
