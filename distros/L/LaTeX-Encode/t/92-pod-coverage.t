#!/usr/bin/perl
# $Id: 92-pod-coverage.t 30 2012-09-25 20:24:40Z andrew $

use strict;
use Test::More;

plan( skip_all => 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.' )
    unless $ENV{TEST_AUTHOR};

eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;
all_pod_coverage_ok();
