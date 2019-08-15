#!perl -T

use strict;
use warnings FATAL => 'all';
use Test::More;

my $min_tcm = 0;
eval "useTest::Perl::Critic $min_tcm";
plan skip_all => "Test::Perl::Critic $min_tcm required" if $@;

Test::Perl::Critic::all_critic_ok();
