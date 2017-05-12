#!perl
use strict;
use warnings;
use Test::More;

eval "use Test::Perl::Critic";
plan skip_all => "Test::Perl::Critic required for testing PBP compliance"
	if $@;

plan skip_all => "Author test. Set \$ENV{TEST_AUTHOR} to a true value to run."
	unless $ENV{TEST_AUTHOR};


Test::Perl::Critic::all_critic_ok();
