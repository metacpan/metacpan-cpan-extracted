#!perl 

use Test::More;
use warnings;
use strict;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;
all_pod_coverage_ok();

