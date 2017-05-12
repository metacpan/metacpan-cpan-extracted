#!perl -T

use strict;
use warnings;

eval {
    require Test::Pod::Coverage;
    Test::Pod::Coverage->import();
    die unless $Test::Pod::Coverage::VERSION >= 1.04;
};
use Test::More;
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok();
