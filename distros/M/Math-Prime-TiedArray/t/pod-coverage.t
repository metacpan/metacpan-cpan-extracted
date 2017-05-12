#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
  if $@;
plan skip_all => 'Skipping maintainer tests without $ENV{AUTHOR_TESTS}' unless $ENV{AUTHOR_TESTS}; 
all_pod_coverage_ok();
