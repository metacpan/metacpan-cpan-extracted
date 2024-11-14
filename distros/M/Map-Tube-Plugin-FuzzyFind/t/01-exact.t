#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;

eval 'use Map::Tube::London 1.39';
plan skip_all => 'Map::Tube::London (>= 1.39) required for this test' if $@;

plan tests => 13;

sub a2n { return [ map { $_->name( ) } @{ $_[0] } ]; }

my $tube = new_ok( 'Map::Tube::London' );
my $ret;

$ret = $tube->fuzzy_find( 'Bakerloo', objects => 'lines' );
is( $ret, 'Bakerloo', 'Finding Bakerloo exactly (up to case)' );

$ret = $tube->fuzzy_find( 'BAKERLOO', objects => 'lines' );
is( $ret, 'Bakerloo', 'Finding Bakerloo exactly (all caps)' );

$ret = $tube->fuzzy_find( 'Waterloo', objects => 'lines' );
is( $ret, undef, 'Finding Waterloo exactly should fail' );

$ret = [ $tube->fuzzy_find( 'Bakerloo',   objects => 'lines' ) ];
is_deeply($ret, [ 'Bakerloo' ], 'Finding Bakerloo exactly (up to case)');

$ret = [ $tube->fuzzy_find( 'BAKERLOO',   objects => 'lines' ) ];
is_deeply($ret, [ 'Bakerloo' ], 'Finding Bakerloo exactly (all caps)');

$ret = [ $tube->fuzzy_find( 'Waterloo',   objects => 'lines' ) ];
is_deeply($ret, [ ], 'Finding Waterloo exactly should fail');

$ret = $tube->fuzzy_find( 'Baker Street', objects => 'stations' );
ok($ret, 'Finding Baker Street exactly');
is($ret->name(), 'Baker Street', 'Finding Baker exactly') if $ret;

$ret = $tube->fuzzy_find( 'Baker',        objects => 'stations' );
is($ret, undef, 'Finding Baker exactly should fail');

$ret = [ $tube->fuzzy_find( 'Baker Street', objects => 'stations' ) ];
ok($ret, 'Finding Baker Street exactly');
is_deeply( a2n($ret), [ 'Baker Street' ], 'Finding Baker exactly') if $ret;

$ret = [ $tube->fuzzy_find( 'Baker',        objects => 'stations' ) ];
is_deeply($ret, [ ], 'Finding Baker exactly should fail');

