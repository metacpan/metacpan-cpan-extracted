#!perl

use Test::More;

plan skip_all => "developer-only tests" unless -d ".svn";

plan skip_all => "Test::Perl::Critic required"
    unless eval { require Test::Perl::Critic };

Test::Perl::Critic::all_critic_ok();
