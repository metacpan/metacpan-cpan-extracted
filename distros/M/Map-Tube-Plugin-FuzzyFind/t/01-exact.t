#!perl
use 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82 tests => 13;
use lib 't/';
use Sample;

sub a2n { return [ map { $_->name( ) } @{ $_[0] } ]; }

my $tube = new_ok( 'Sample' );
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

