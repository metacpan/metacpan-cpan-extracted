#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required" if $@;

my @mods = all_modules();
plan tests => scalar @mods;

pod_coverage_ok($_) for @mods;
