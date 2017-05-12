#!/usr/bin/perl
use strict;
use Test::More 'no_plan';

BEGIN { use_ok( 'List::Comprehensions' ); }

my @c1 = comp1 { [ @_ ] } [0..4], [0..4], [0..4];

no warnings 'once';
no strict 'vars';

my @c2 = comp2 { [$i, $j, $k] }
	i => [0..4],
	j => [0..4],
	k => [0..4];
	
use strict 'vars';
use warnings 'once';

my ($i, $j, $k) = ('lexical', 'values', 'before');

my @c3 = comp2 { [$i, $j, $k] }
	i => [0..4],
	j => [0..4],
	k => [0..4];

cmp_ok( $i, 'eq', 'lexical' );
cmp_ok( $j, 'eq', 'values' );
cmp_ok( $k, 'eq', 'before' );

# each being less efficient but equivelant to

my @c4 = ();
for $i ( 0..4 ) {
	for $j ( 0..4 ) {
		for $k ( 0..4 ) {
			push @c4, [$i, $j, $k];
		}
	}
}

is_deeply(\@c1, \@c2);
is_deeply(\@c2, \@c3);
is_deeply(\@c3, \@c4);

