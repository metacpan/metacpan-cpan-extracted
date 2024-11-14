#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;

eval 'use Map::Tube::London 1.39';
plan skip_all => 'Map::Tube::London (>= 1.39) required for this test' if $@;

plan tests => 19;

sub a2n { return [ map { $_->name( ) } @{ $_[0] } ]; }

my $tube = new_ok( 'Map::Tube::London' );
my $ret;

$ret = $tube->fuzzy_find( '[kx]erloo', objects => 'lines', method => 're' );
is( $ret, 'Bakerloo', 'Finding regex [kx]erloo' );

$ret = $tube->fuzzy_find( '[tx]erloo', objects => 'lines', method => 're' );
is( $ret, 'Waterloo and City', 'Finding regex [tx]erloo' );

$ret = $tube->fuzzy_find( '[ktx]erloo', objects => 'lines', method => 're' );
is( $ret, 'Bakerloo', 'Finding regex [ktx]erloo' );

$ret = [ $tube->fuzzy_find( '[kx]erloo',  objects => 'lines', method => 're' ) ];
is_deeply($ret, [ 'Bakerloo' ], 'Finding regex [kx]erloo');

$ret = [ $tube->fuzzy_find( '[tx]erloo',  objects => 'lines', method => 're' ) ];
is_deeply($ret, [ 'Waterloo and City' ], 'Finding regex [tx]erloo');

$ret = [ $tube->fuzzy_find( '[ktx]erloo', objects => 'lines', method => 're' ) ];
is_deeply($ret, [ 'Bakerloo',  'Waterloo and City'  ], 'Finding regex [ktx]erloo');

$ret = $tube->fuzzy_find( '[kx]er',       objects => 'stations', method => 're' );
ok($ret, 'Finding regex [kx]er');
is($ret->name(), 'Baker Street', 'Finding regex [kx]er');

$ret = $tube->fuzzy_find( '[ax]ter',       objects => 'stations', method => 're' );
ok($ret, 'Finding regex [ax]ter');
is($ret->name(), 'Bayswater', 'Finding regex [ax]ter');

$ret = $tube->fuzzy_find( '[atx]ker',      objects => 'stations', method => 're' );
ok($ret, 'Finding regex [atx]ker');
is($ret->name(), 'Baker Street', 'Finding regex [atx]ter');

$ret = [ $tube->fuzzy_find( '[kx]er',       objects => 'stations', method => 're' ) ];
ok($ret, 'Finding regex [kx]er');
is_deeply( a2n($ret), [ 'Baker Street' ], 'Finding regex [kx]er');

$ret = [ $tube->fuzzy_find( '[sx]ters',      objects => 'stations', method => 're' ) ];
ok($ret, 'Finding regex [sx]ters');
is_deeply( a2n($ret), [ 'Cockfosters', 'Seven Sisters' ], 'Finding regex [sx]ters');

$ret = [ $tube->fuzzy_find( 'a[ktx]er',     objects => 'stations', method => 're' ) ];
ok($ret, 'Finding regex a[ktx]er');
is_deeply( a2n($ret), [ 'Baker Street', 'Bayswater', 'Canada Water', 'Waterloo' ], 'Finding regex a[ktx]er');

