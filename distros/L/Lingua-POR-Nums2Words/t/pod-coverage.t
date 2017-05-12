#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok();
