#!/usr/bin/env perl

use Test::More;
if ( !require Test::Perl::Critic ) {
    plan skip_all => "Test::Perl::Critic required for testing PBP compliance" ;
}

if ( not( $ENV{AUTHOR_TESTING} or $ENV{RELEASE_TESTING} ) ) {
    plan skip_all => "This test is for authors only" ;
}

Test::Perl::Critic::all_critic_ok(qw/lib/);
