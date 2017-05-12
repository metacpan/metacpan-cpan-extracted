#! /usr/bin/env perl

use v5.10;
use warnings;

use Test::More tests=>1;

use lib::abs qw(../lib);

my $app_root_path = lib::abs::path('.'); 

do './ex/change_engine_example.pl';

ok (!$@, 'change_engine_example.pl worked');