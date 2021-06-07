#!/usr/bin/perl

use strict;
use warnings;

use Math::Random::Free qw( random_exponential
                           random_normal
                           random_permutation
                           random_set_seed_from_phrase
                           random_uniform_integer );
use Test::More;

my @tested = (
    sub { return random_uniform_integer( 1, 1, 123 ) },
    sub { return join ',', random_permutation( 0..9 ) },
    sub { return join ',', random_normal( 5 ) },
    sub { return random_exponential },
);
plan tests => scalar @tested;

sub seed_and_test
{
    my( $function ) = @_;
    random_set_seed_from_phrase( 'Math::Random::Free' );
    return $function->();
}

for (@tested) {
    is( seed_and_test( $_ ), seed_and_test( $_ ) );
}
