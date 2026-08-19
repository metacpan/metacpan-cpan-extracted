#!/usr/bin/env perl
# Author test: everything under eg/ must at least compile against the build.
use strict;
use warnings;
use Test::More;

my @examples = sort glob 'eg/*.pl';
plan skip_all => 'no examples found' unless @examples;
plan tests => scalar @examples;

for my $example (@examples) {
    my $output = `$^X -Iblib/lib -Iblib/arch -c $example 2>&1`;
    is($? >> 8, 0, "$example compiles") or diag $output;
}
