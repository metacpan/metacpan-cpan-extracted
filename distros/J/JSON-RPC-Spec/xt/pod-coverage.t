use strict;
use Test::More;

eval 'use Test::Pod::Coverage;';
plan skip_all => 'Test::Pod::Coverage required for this test.' if $@;

all_pod_coverage_ok();
