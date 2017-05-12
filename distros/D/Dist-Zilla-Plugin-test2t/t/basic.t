#!/usr/bin/perl
use strict;
use warnings;
use Test::More ( tests => 1 );
use Test::DZil;

my $tzil = Builder->from_config( { dist_root => 'corpus/DZT' } );
$tzil->build;

my $test = $tzil->slurp_file('build/t/01-basic.t');
like $test, qr/"Works great!"/;
