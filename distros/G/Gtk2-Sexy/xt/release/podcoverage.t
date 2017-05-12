#!perl

use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage';
plan skip_all => 'Test::Pod::Coverage required' if $@;

use Gtk2 -init;

plan tests => 1;
pod_coverage_ok('Gtk2::Sexy', { trustme => ['dl_load_flags'] });
