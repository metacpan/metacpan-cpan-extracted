#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;

eval 'use Map::Tube::London';
plan skip_all => 'Map::Tube::London required for this test' if $@;

plan tests => 19;

sub a2n { return [ map { $_->name() } @{ $_[0] } ]; }

my $tube = Map::Tube::London->new();
my $ret;

$ret = $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'start' );
is( $ret, 'Bakerloo', 'Finding Bakerloo at start' );

$ret = $tube->fuzzy_find( 'Waterloo', objects => 'lines', method => 'start' );
is( $ret, 'Waterloo & City', 'Finding Waterloo at start' );

$ret = $tube->fuzzy_find( 'kerloo', objects => 'lines', method => 'start' );
is( $ret, undef, 'Finding kerloo at start should fail' );

$ret = [ $tube->fuzzy_find( 'Bakerloo',   objects => 'lines', method => 'start' ) ];
is_deeply($ret, [ 'Bakerloo' ], 'Finding Bakerloo at start');

$ret = [ $tube->fuzzy_find( 'Waterloo',   objects => 'lines', method => 'start' ) ];
is_deeply($ret, [ 'Waterloo & City' ], 'Finding Waterloo at start');

$ret = [ $tube->fuzzy_find( 'kerloo',     objects => 'lines', method => 'start' ) ];
is_deeply($ret, [ ], 'Finding kerloo at start should fail');

$ret = [ $tube->fuzzy_find( 'C',          objects => 'lines', method => 'start' ) ];
is_deeply($ret, [ 'Central', 'Circle' ], 'Finding C at start');

$ret = $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'start' );
ok($ret, 'Finding Baker Street at start');
is($ret->name(), 'Baker Street', 'Finding Baker at start') if $ret;

$ret = $tube->fuzzy_find( 'Baker',        objects => 'stations', method => 'start' );
ok($ret, 'Finding Baker at start');
is($ret->name(), 'Baker Street', 'Finding Baker at start') if $ret;

$ret = $tube->fuzzy_find( 'Bakerx',       objects => 'stations', method => 'start' );
is($ret, undef, 'Finding Bakerx at start should fail');

$ret = $tube->fuzzy_find( 'ker',          objects => 'stations', method => 'start' );
is($ret, undef, 'Finding ker at start should fail');

$ret = [ $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'start' ) ];
ok($ret, 'Finding Baker Street at start');
is_deeply( a2n($ret), [ 'Baker Street' ], 'Finding Baker at start') if $ret;

$ret = [ $tube->fuzzy_find( 'Baker',        objects => 'stations', method => 'start' ) ];
ok($ret, 'Finding Baker at start');
is_deeply( a2n($ret), [ 'Baker Street' ], 'Finding Baker at start') if $ret;

$ret = [ $tube->fuzzy_find( 'Bakerx',       objects => 'stations', method => 'start' ) ];
is_deeply($ret, [ ], 'Finding Bakerx at start should fail');

$ret = [ $tube->fuzzy_find( 'ker',          objects => 'stations', method => 'start' ) ];
is_deeply($ret, [ ], 'Finding ker at start should fail');

