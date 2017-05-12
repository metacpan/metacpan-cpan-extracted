#!perl -T

use Test::More;

plan skip_all => "Documentation tests are disabled" if $ENV{TEST_POD_SKIP};

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok();

