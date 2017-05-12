#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use Test::More ( tests => 1 );
use Test::DZil;

my $tzil = Builder->from_config( { dist_root => 'corpus/DZT2' } );
$tzil->build;

my $contents = $tzil->slurp_file('build/Changes');
$contents =~ s/^$//m;

is( $contents, <<'CHANGES', "Changes got converted correctly" );
0.37 2013-10-25 21:46:59 +0800
 - Bugfix: Run Test::Compile tests as xt as they require optional
   dependencies to be present (GH issue #22)
 - Testing: Added Travis-CI integration
 - Makefile: Added target to update version on all packages

0.36 2013-10-20 04:44:42 +0800
 - Move the distribution to Dist::Zilla

0.35 2013-05-27 14:23:42 -0700
 - Forgot to merge doc changes from CarlosLima++
CHANGES
