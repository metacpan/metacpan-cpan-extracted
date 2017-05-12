#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;

eval 'use Map::Tube::London';
plan skip_all => 'Map::Tube::London required for this test' if $@;

plan tests => 18;

sub a2n { return [ map { $_->name() } @{ $_[0] } ]; }

my $tube = Map::Tube::London->new();
my $ret;

$ret = $tube->fuzzy_find( '[kx]erloo', objects => 'lines', method => 're' );
is( $ret, 'Bakerloo', 'Finding regex [kx]erloo' );

$ret = $tube->fuzzy_find( '[tx]erloo', objects => 'lines', method => 're' );
is( $ret, 'Waterloo & City', 'Finding regex [tx]erloo' );

$ret = $tube->fuzzy_find( '[ktx]erloo', objects => 'lines', method => 're' );
is( $ret, 'Bakerloo', 'Finding regex [ktx]erloo' );

$ret = [ $tube->fuzzy_find( '[kx]erloo',  objects => 'lines', method => 're' ) ];
is_deeply($ret, [ 'Bakerloo' ], 'Finding regex [kx]erloo');

$ret = [ $tube->fuzzy_find( '[tx]erloo',  objects => 'lines', method => 're' ) ];
is_deeply($ret, [ 'Waterloo & City' ], 'Finding regex [tx]erloo');

$ret = [ $tube->fuzzy_find( '[ktx]erloo', objects => 'lines', method => 're' ) ];
is_deeply($ret, [ 'Bakerloo',  'Waterloo & City'  ], 'Finding regex [ktx]erloo');

$ret = $tube->fuzzy_find( '[kx]er',       objects => 'stations', method => 're' );
ok($ret, 'Finding regex [kx]er');
is($ret->name(), 'Baker Street', 'Finding regex [kx]er');

$ret = $tube->fuzzy_find( '[tx]er',       objects => 'stations', method => 're' );
ok($ret, 'Finding regex [tx]er');
is($ret->name(), 'Bayswater', 'Finding regex [tx]er');

$ret = $tube->fuzzy_find( '[ktx]er',      objects => 'stations', method => 're' );
ok($ret, 'Finding regex [ktx]er');
is($ret->name(), 'Baker Street', 'Finding regex [ktx]er');

$ret = [ $tube->fuzzy_find( '[kx]er',       objects => 'stations', method => 're' ) ];
ok($ret, 'Finding regex [kx]er');
is_deeply( a2n($ret), [ 'Baker Street' ], 'Finding regex [kx]er');

$ret = [ $tube->fuzzy_find( '[tx]ers',      objects => 'stations', method => 're' ) ];
ok($ret, 'Finding regex [tx]ers');
is_deeply( a2n($ret), [ 'Cockfosters', 'Seven Sisters' ], 'Finding regex [tx]ers');

$ret = [ $tube->fuzzy_find( 'a[ktx]er',     objects => 'stations', method => 're' ) ];
ok($ret, 'Finding regex a[ktx]er');
is_deeply( a2n($ret), [ 'Baker Street', 'Bayswater', 'Canada Water', 'Waterloo' ], 'Finding regex a[ktx]er');

