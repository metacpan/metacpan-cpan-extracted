#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use English '-no_match_vars';

if ( not $ENV{RELEASE_TESTING} ) {
  my $msg = 'Author Test: Set $ENV{RELEASE_TESTING} to run.';
  plan skip_all => $msg;
}

eval { require Test::Perl::Critic; }; ## no critic (eval)
if ( $EVAL_ERROR ) {
  my $msg = 'Author Test: Test::Perl::Critic required for critique.';
  plan skip_all => $msg;
}

Test::Perl::Critic->import(-severity => 5);

my @directories = qw{ blib/ t/ };
Test::Perl::Critic::all_critic_ok(@directories);
