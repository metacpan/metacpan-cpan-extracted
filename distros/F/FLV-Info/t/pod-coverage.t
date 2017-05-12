#!perl
use warnings;
use strict;
use Test::More;

if ((!$ENV{AUTHOR_TEST} && !$ENV{AUTHOR_TEST_CDOLAN}) ||
    $ENV{AUTOMATED_TESTING})
{
   plan skip_all => 'Author test';
}
eval 'use Pod::Coverage 0.17 ()';
plan skip_all => 'Optional Pod::Coverage 0.17 not found' if $@;
eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Optional Test::Pod::Coverage 1.04 not found' if $@;
all_pod_coverage_ok();
