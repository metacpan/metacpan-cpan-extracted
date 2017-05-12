#!/usr/bin/perl

# Test POD coverage for SMS::AQL
#
# $Id: 3-pod-coverage.t 155 2007-06-26 20:18:51Z davidp $


use strict;
use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" 
    if $@;
all_pod_coverage_ok();