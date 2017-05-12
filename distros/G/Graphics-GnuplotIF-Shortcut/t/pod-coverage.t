#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage\nAlso we skip the test for CPAN Testers, many of them report false positives for inherited method documentation." if $@ or $ENV{AUTOMATED_TESTING};
all_pod_coverage_ok();
