#!perl

use strict;
use Test::More;

plan skip_all => '$ENV{TEST_CRITIC} must be set to enable this test'
    unless $ENV{TEST_CRITIC};

eval { require Test::Perl::Critic };
plan skip_all => 'Test::Perl::Critic required to enable this test' if $@;

Test::Perl::Critic::all_critic_ok();
