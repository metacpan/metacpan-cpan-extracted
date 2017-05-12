#!perl
use Test::More;
eval "use Test::Perl::Critic";
if ( $@ ) { plan skip_all => "Test::Perl::Critic required for criticism" }
all_critic_ok();
