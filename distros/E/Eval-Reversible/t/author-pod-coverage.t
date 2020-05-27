#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use v5.10.1;
use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Require::AuthorTesting;
use Test::Pod::Coverage 0.08;

my %exceptions = (
);

my @modules = all_modules();

plan tests => scalar @modules;

foreach my $module (@modules) {
    pod_coverage_ok($module, $exceptions{$module});
}

done_testing;
