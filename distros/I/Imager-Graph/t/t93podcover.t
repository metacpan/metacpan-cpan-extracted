#!perl -w
use strict;
use Test::More;
$ENV{AUTOMATED_TESTING} || $ENV{IMAGER_AUTHOR_TESTING}
  or plan skip_all => "POD only tested under automated or author testing";
eval "use Test::Pod::Coverage 1.08;";
# 1.08 required for coverage_class support
plan skip_all => "Test::Pod::Coverage 1.08 required for POD coverage" if $@;

all_pod_coverage_ok();
