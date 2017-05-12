#!/usr/bin/perl

use Test::More 'no_plan';

my $class = 'Distribution::Cooker';
my $dist  = 'Foo-Bar';

use_ok( $class );
can_ok( $class, 'dist' );

my $cooker = $class->new;
isa_ok( $cooker, $class );

ok( ! $cooker->dist, "There is nothing in dist at start" );
is( $cooker->dist( $dist ), $dist, "Set dist and return it" );
is( $cooker->dist, $dist, "Remembers dist name" );