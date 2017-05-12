#!perl -T

use Test::More;
plan skip_all => 'env AUTOMATED_TESTING=1 and Test::Pod::Coverage 1.04 required for testing POD coverage' unless $ENV{AUTOMATED_TESTING};
eval "use Test::Pod::Coverage 1.04";
plan skip_all => 'env AUTOMATED_TESTING=1 and Test::Pod::Coverage 1.04 required for testing POD coverage' if $@;
all_pod_coverage_ok();
