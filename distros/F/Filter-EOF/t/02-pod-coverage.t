#!perl
use warnings;
use strict;

use Test::More;
eval 'use Test::Pod::Coverage';
plan skip_all => 'Test::Pod::Coverage required to run POD coverage tests' if $@;

all_pod_coverage_ok();


