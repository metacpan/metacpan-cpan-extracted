#!perl

use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
eval("use Test::Pod::Coverage 1.08");
if ($@) {
    plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage";
    exit(0);
}

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
eval("use Pod::Coverage 0.18");
if ($@) {
    plan skip_all => "Pod::Coverage 0.18 required for testing POD coverage";
    exit(0);
}

plan tests => 5;
foreach my $module (all_modules()) {
    pod_coverage_ok($module) unless $module =~ /(NULL|ZERO)/;
}
