#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More ( tests => 1 );
use Test::DZil;

my $tzil = Builder->from_config( { dist_root => 'corpus/DZT' } );
$tzil->build;

my $contents = $tzil->slurp_file('build/Changes');
$contents =~ s/^$//m;

is( $contents, <<'CHANGES', "Changes got converted correctly" );
0.37 Fri Oct 25 21:46:59 MYT 2013
 - Bugfix: Run Test::Compile tests as xt as they require optional
   dependencies to be present (GH issue #22)
 - Testing: Added Travis-CI integration
 - Makefile: Added target to update version on all packages
 - ∮ E⋅da = Q, n → ∞, ∑ f(i) = ∏ g(i)

0.36 Sun Oct 20 04:44:42 MYT 2013
 - Move the distribution to Dist::Zilla

0.35 Mon May 27 14:23:42 PDT 2013
 - Forgot to merge doc changes from CarlosLima++
CHANGES
