#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
    use_ok( 'Git::Diff' ) || print "Bail out!\n";
}

diag( "Testing Git::Diff $Git::Diff::VERSION, Perl $], $^X" );

my $o_git_dif = new_ok('Git::Diff');

