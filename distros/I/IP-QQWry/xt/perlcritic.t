use strict;
use warnings;

use Test::More;

eval "use Test::Perl::Critic 0.0.8";
plan skip_all => "Test::Perl::Critic 0.0.8 required for testing PBP complicance" if $@;

Test::Perl::Critic::all_critic_ok();
