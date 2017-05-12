use strict;
use warnings;
eval q[use Test::Perl::Critic];
plan(skip_all => "Test::Perl::Critic required for testing PBP compliance") if $@;

Test::Perl::Critic::all_critic_ok();
