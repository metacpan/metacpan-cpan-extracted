#!perl

use Test::More;

eval "use Test::Pod::Critic";
plan skip_all => "Test::Pod::Critic required for testing POD coverage" if $@;

Test::Perl::Critic::all_critic_ok();
