#!perl
# use Test::Without::Module qw( Test::Perl::Critic );
use Test::More;

plan skip_all => 'env AUTOMATED_TESTING=1 and Test::Perl::Critic required for testing PBP compliance' unless $ENV{AUTOMATED_TESTING};

eval {require Test::Perl::Critic};
plan skip_all => "Test::Perl::Critic required for testing PBP compliance" if $@;

Test::Perl::Critic::all_critic_ok();
