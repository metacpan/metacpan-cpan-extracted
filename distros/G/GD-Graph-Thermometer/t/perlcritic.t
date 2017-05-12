#!/usr/bin/perl -w
# use Test::More tests => 1;
use Test::More;

# SKIP:
# {
# 
#   eval 'use Test::Perl::Critic';
#   skip('because Test::Perl::Critic required for these tests.',1) if $@;
#   Test::Perl::Critic::all_critic_ok();
# 
# }

eval "use Test::Perl::Critic";
if ( $@ ) {
    plan skip_all => "because Test::Perl::Critic required for these tests";
} else {
    all_critic_ok();
}
