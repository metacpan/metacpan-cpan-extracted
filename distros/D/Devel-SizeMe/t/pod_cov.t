#!/usr/bin/perl -w

use Test::More;
use strict;

plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage"
    unless eval "use Test::Pod::Coverage 1.08; 1";

my $tests = 1;
plan tests => $tests;
chdir 't' if -d 't';

use lib '../lib';

for my $m (qw(
    Devel::SizeMe
)) {
    pod_coverage_ok( $m, "$m is covered" );
}

