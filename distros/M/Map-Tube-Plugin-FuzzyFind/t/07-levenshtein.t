#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;

eval 'use Map::Tube 2.93';
plan skip_all => 'Map::Tube 2.93 required for this test' if $@;

eval 'use Map::Tube::London 0.71';
plan skip_all => 'Map::Tube::London 0.71 required for this test' if $@;

eval 'use Text::Levenshtein';
plan skip_all => 'Text::Levenshtein required for this test' if $@;

plan tests => 26;

sub a2n { return [ map { $_->name() } @{ $_[0] } ]; }

my $tube = new_ok( 'Map::Tube::London' );
my $ret;

$ret = $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'levenshtein' );
is( $ret, 'Bakerloo', 'Finding Bakerloo fuzzy' );

$ret = $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'levenshtein', maxdist => 6 );
is( $ret, 'Bakerloo', 'Finding line Packalu fuzzy with distance 6' );

$ret = $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'levenshtein' );
is( $ret, undef, 'Finding line Packalu fuzzy with standard distance should fail' );

$ret = $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'levenshtein', maxdist => 5 );
is( $ret, undef, 'Finding line Packalu fuzzy with distance 5 should fail' );

$ret = [ $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'levenshtein' ) ];
is_deeply($ret, [ 'Bakerloo' ], 'Finding many lines Bakerloo fuzzy');

$ret = [ $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'levenshtein', maxdist => 6 ) ];
is_deeply($ret, [ 'Bakerloo', 'Central', 'Circle', 'DLR', 'Piccadilly' ], 'Finding many lines Packalu fuzzy with distance 6');

$ret = [ $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'levenshtein', maxdist => 5 ) ];
is_deeply($ret, [ ], 'Finding many lines Packalu fuzzy with distance 5 should fail');

$ret = [ $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'levenshtein' ) ];
is_deeply($ret, [ ], 'Finding many lines Packalu fuzzy with standard distance should fail');

$ret = $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'levenshtein' );
ok($ret, 'Finding Baker Street fuzzy');
is($ret->name(), 'Baker Street', 'Finding station Baker Street fuzzy');

$ret = $tube->fuzzy_find( 'Baker', objects => 'stations', method => 'levenshtein' );
ok($ret, 'Finding Baker fuzzy');
is($ret->name(), 'Bank', 'Finding station Baker fuzzy');

$ret = $tube->fuzzy_find( 'Paisvatr', objects => 'stations', method => 'levenshtein' );
ok($ret, 'Finding Paisvatr fuzzy');
is($ret->name(), 'Bayswater', 'Finding station Paisvatr fuzzy');

$ret = $tube->fuzzy_find( 'Beisvtr', objects => 'stations', method => 'levenshtein', maxdist => 6 );
ok($ret, 'Finding Beisvtr fuzzy with distance 6');
is($ret->name(), 'Bayswater', 'Finding station Beisvtr fuzzy at max distance 6');

$ret = $tube->fuzzy_find( 'Beisvtr', objects => 'stations', method => 'levenshtein' );
is($ret, undef, 'Finding station Beisvtr fuzzy at standard max distance should fail');

$ret = $tube->fuzzy_find( 'Beisvtr', objects => 'stations', method => 'levenshtein', maxdist => 4 );
is($ret, undef, 'Finding station Beisvtr fuzzy at max distance 4 should fail');

$ret = [ $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'levenshtein', maxdist => 4 ) ];
is_deeply( a2n($ret), [ 'Baker Street', 'Bond Street' ], 'Finding many stations Baker Street fuzzy at max distance 4');

$ret = [ $tube->fuzzy_find( 'Baker', objects => 'stations', method => 'levenshtein' ) ];
is_deeply( a2n($ret), [ 'Bank' ], 'Finding many stations Baker fuzzy');

$ret = [ $tube->fuzzy_find( 'Paisvatr', objects => 'stations', method => 'levenshtein' ) ];
is_deeply( a2n($ret), [ 'Bayswater' ], 'Finding many stations Paisvatr fuzzy');

$ret = [ $tube->fuzzy_find( 'Bxxtree', objects => 'stations', method => 'levenshtein', maxdist => 4 ) ];
is_deeply( a2n($ret), [ 'Becontree' ], 'Finding many stations Bxxtree fuzzy at max distance 4');

$ret = [ $tube->fuzzy_find( 'Bxxtree', objects => 'stations', method => 'levenshtein', maxdist => 5 ) ];
is_deeply( a2n($ret), [ 'Becontree', 'Brixton', 'Bushey', 'Hoxton' ], 'Finding many stations Bxxtree fuzzy at max distance 5');

$ret = [ $tube->fuzzy_find( 'Bxxtree', objects => 'stations', method => 'levenshtein' ) ];
is_deeply( a2n($ret), [ 'Becontree' ], 'Finding many stations Bxxtree fuzzy at standard max distance');

$ret = [ $tube->fuzzy_find( 'Bxxtree', objects => 'stations', method => 'levenshtein', maxdist => 3 ) ];
is_deeply($ret, [ ], 'Finding many stations Bxxtree fuzzy at max distance 3 should fail');

