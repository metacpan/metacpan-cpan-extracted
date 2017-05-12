use strict;
use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;
plan skip_all => 'does not need to document methods';
all_pod_coverage_ok();
