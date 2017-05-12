#!perl -T

use Test::More;
eval "use Test::Perl::Critic (-severity => 'cruel')";
plan skip_all => "Test::Perl::Critic required for testing coding best practices" if $@;
all_critic_ok();
