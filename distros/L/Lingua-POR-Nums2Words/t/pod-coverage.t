#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok();
