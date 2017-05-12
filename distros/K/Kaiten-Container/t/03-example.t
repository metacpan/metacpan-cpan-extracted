#! /usr/bin/env perl

use v5.10;
use warnings;

use Test::More tests=>1;

use lib::abs qw(../lib);

my $app_root_path = lib::abs::path('.'); 

do './ex/simple_example.pl';

ok (!$@, 'simple_example.pl worked');
