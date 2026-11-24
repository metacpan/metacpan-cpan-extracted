#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;

unless ( $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING} ) {
    plan( skip_all => 'Author/Release tests not required for installation' );
}

eval 'use Test::Perl::Critic';
plan( skip_all => 'Test::Perl::Critic required for testing code quality' ) if $@;

my $root = File::Spec->rel2abs('../..');
my $rcfile = File::Spec->catfile($root, '.perlcriticrc');
if (-f $rcfile) {
    Test::Perl::Critic->import( -profile => $rcfile );
}

all_critic_ok('lib');
