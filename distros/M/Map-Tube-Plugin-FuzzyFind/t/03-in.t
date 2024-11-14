#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;

eval 'use Map::Tube::London 1.39';
plan skip_all => 'Map::Tube::London (>= 1.39) required for this test' if $@;

plan tests => 23;

sub a2n { return [ map { $_->name( ) } @{ $_[0] } ]; }

my $tube = new_ok( 'Map::Tube::London' );
my $ret;

$ret = $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'in' );
is( $ret, 'Bakerloo', 'Finding Bakerloo somewhere' );

$ret = $tube->fuzzy_find( 'Waterloo', objects => 'lines', method => 'in' );
is( $ret, 'Waterloo and City', 'Finding Waterloo somewhere' );

$ret = $tube->fuzzy_find( 'kerloo', objects => 'lines', method => 'in' );
is( $ret, 'Bakerloo', 'Finding kerloo somewhere' );

$ret = $tube->fuzzy_find( 'xerloo', objects => 'lines', method => 'in' );
is( $ret, undef, 'Finding xerloo somewhere should fail' );

$ret = [ $tube->fuzzy_find( 'Bakerloo',   objects => 'lines', method => 'in' ) ];
is_deeply($ret, [ 'Bakerloo' ], 'Finding Bakerloo somewhere');

$ret = [ $tube->fuzzy_find( 'Waterloo',   objects => 'lines', method => 'in' ) ];
is_deeply($ret, [ 'Waterloo and City' ], 'Finding Waterloo somewhere');

$ret = [ $tube->fuzzy_find( 'kerloo',     objects => 'lines', method => 'in' ) ];
is_deeply($ret, [ 'Bakerloo' ], 'Finding kerloo somewhere');

$ret = [ $tube->fuzzy_find( 'xerloo',     objects => 'lines', method => 'in' ) ];
is_deeply($ret, [ ], 'Finding xerloo somewhere should fail');

$ret = $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'in' );
ok($ret, 'Finding Baker Street somewhere');
is($ret->name(), 'Baker Street', 'Finding Baker somewhere');

$ret = $tube->fuzzy_find( 'Baker',        objects => 'stations', method => 'in' );
ok($ret, 'Finding Baker somewhere');
is($ret->name(), 'Baker Street', 'Finding Baker somewhere');

$ret = $tube->fuzzy_find( 'ker',          objects => 'stations', method => 'in' );
ok($ret, 'Finding ker somewhere');
is($ret->name(), 'Baker Street', 'Finding ker somewhere');

$ret = $tube->fuzzy_find( 'xer',          objects => 'stations', method => 'in' );
is($ret, undef, 'Finding xer somewhere should fail');

$ret = [ $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'in' ) ];
ok($ret, 'Finding Baker Street somewhere');
is_deeply( a2n($ret), [ 'Baker Street' ], 'Finding Baker somewhere');

$ret = [ $tube->fuzzy_find( 'Baker',        objects => 'stations', method => 'in' ) ];
ok($ret, 'Finding Baker somewhere');
is_deeply( a2n($ret), [ 'Baker Street' ], 'Finding Baker somewhere');

$ret = [ $tube->fuzzy_find( 'ker',          objects => 'stations', method => 'in' ) ];
ok($ret, 'Finding ker somewhere');
is_deeply( a2n($ret), [ 'Baker Street' ], 'Finding ker somewhere');

$ret = [ $tube->fuzzy_find( 'xer',          objects => 'stations', method => 'in' ) ];
is_deeply($ret, [ ], 'Finding xer somewhere should fail');

