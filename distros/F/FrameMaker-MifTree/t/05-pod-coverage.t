#!/usr/bin/perl
# $Id: 05-pod-coverage.t 2 2006-05-02 11:15:26Z roel $
use strict;
use warnings;
use Test::More;
eval 'use Test::Pod::Coverage';
plan skip_all => 'Test::Pod::Coverage 1.00 required for testing POD coverage'
  if $@;
all_pod_coverage_ok();

__END__
