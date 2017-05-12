#!perl -T

use constant RUN_AUTHOR_ONLY_TESTS => 0;
use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
    if $@;
plan skip_all => "Only run during development" unless RUN_AUTHOR_ONLY_TESTS;
all_pod_coverage_ok();
