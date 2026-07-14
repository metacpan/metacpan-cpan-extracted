use strict;
use warnings;
use Test::More;

unless ( $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING} ) {
    plan( skip_all => 'Author tests not required for installation' );
}

eval 'use Test::Perl::Critic';
plan( skip_all => 'Test::Perl::Critic required for testing PBP compliance' ) if $@;

all_critic_ok();
