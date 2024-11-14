#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;

eval 'use Map::Tube::London';
plan skip_all => 'Map::Tube::London required for this test' if $@;

eval 'use String::Trigram';
plan skip_all => 'String::Trigram required for this test' if $@;

plan tests => 26;

sub a2n { return [ map { $_->name( ) } @{ $_[0] } ]; }

my $tube = new_ok( 'Map::Tube::London' );
my $ret;

$ret = $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'ngrams' );
is( $ret, 'Bakerloo', 'Finding Bakerloo fuzzy' );

$ret = $tube->fuzzy_find( 'Bagrlo', objects => 'lines', method => 'ngrams', maxdist => 5 );
is( $ret, 'Bakerloo', 'Finding line Bagrlo fuzzy with distance 5' );

$ret = $tube->fuzzy_find( 'Bagrlo', objects => 'lines', method => 'ngrams' );
is( $ret, undef, 'Finding line Bagrlo fuzzy with standard distance should fail' );

$ret = $tube->fuzzy_find( 'Bagrlo', objects => 'lines', method => 'ngrams', maxdist => 3 );
is( $ret, undef, 'Finding line Bagrlo fuzzy with distance 3 should fail' );

$ret = [ $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'ngrams' ) ];
is_deeply($ret, [ 'Bakerloo' ], 'Finding many lines Bakerloo fuzzy');

$ret = [ $tube->fuzzy_find( 'Bagrlo', objects => 'lines', method => 'ngrams', maxdist => 6 ) ];
is_deeply($ret, [ 'Bakerloo', 'Waterloo and City' ], 'Finding many lines Bagrlo fuzzy with distance 6');

$ret = [ $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'ngrams', maxdist => 5 ) ];
is_deeply($ret, [ ], 'Finding many lines Packalu fuzzy with distance 5 should fail');

$ret = [ $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'ngrams' ) ];
is_deeply($ret, [ ], 'Finding many lines Packalu fuzzy with standard distance should fail');

$ret = $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'ngrams' );
ok($ret, 'Finding Baker Street fuzzy');
is($ret->name(), 'Baker Street', 'Finding station Baker Street fuzzy');

$ret = $tube->fuzzy_find( 'Water Street', objects => 'stations', method => 'ngrams' );
ok($ret, 'Finding Water Street fuzzy');
is($ret->name(), 'Baker Street', 'Finding station Water Street fuzzy');

$ret = $tube->fuzzy_find( 'Baisvater', objects => 'stations', method => 'ngrams' );
ok($ret, 'Finding Baisvater fuzzy');
is($ret->name(), 'Bayswater', 'Finding station Baisvater fuzzy');

$ret = $tube->fuzzy_find( 'Beisvtr', objects => 'stations', method => 'ngrams', maxdist => 6 );
ok($ret, 'Finding Beisvtr fuzzy with distance 6');
is($ret->name(), 'Beckton', 'Finding station Beisvtr fuzzy at max distance 6');

$ret = $tube->fuzzy_find( 'Beisvtr', objects => 'stations', method => 'ngrams' );
is($ret, undef, 'Finding station Beisvtr fuzzy at standard max distance should fail');

$ret = $tube->fuzzy_find( 'Beisvtr', objects => 'stations', method => 'ngrams', maxdist => 4 );
is($ret, undef, 'Finding station Beisvtr fuzzy at max distance 4 should fail');

$ret = [ $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'ngrams', maxdist => 5 ) ];
is_deeply( a2n($ret), [ 'Baker Street', 'Silver Street', 'Bond Street', 'Old Street' ], 'Finding many stations Baker Street fuzzy at max distance 4');

$ret = [ $tube->fuzzy_find( 'Banker', objects => 'stations', method => 'ngrams' ) ];
is_deeply( a2n($ret), [ 'Bank' ], 'Finding many stations Baker fuzzy');

$ret = [ $tube->fuzzy_find( 'Baisvater', objects => 'stations', method => 'ngrams' ) ];
is_deeply( a2n($ret), [ 'Bayswater' ], 'Finding many stations Paisvatr fuzzy');

$ret = [ $tube->fuzzy_find( 'Bxxtree', objects => 'stations', method => 'ngrams', maxdist => 4 ) ];
is_deeply( a2n($ret), [ 'Becontree' ], 'Finding many stations Bxxtree fuzzy at max distance 4');

$ret = [ $tube->fuzzy_find( 'Bxxtree', objects => 'stations', method => 'ngrams', maxdist => 5 ) ];
is_deeply( a2n($ret), [ 'Becontree', 'Bond Street', 'Baker Street' ], 'Finding many stations Bxxtree fuzzy at max distance 5');

$ret = [ $tube->fuzzy_find( 'Bxxtree', objects => 'stations', method => 'ngrams' ) ];
is_deeply( a2n($ret), [ 'Becontree' ], 'Finding many stations Bxxtree fuzzy at standard max distance');

$ret = [ $tube->fuzzy_find( 'Bxxtree', objects => 'stations', method => 'ngrams', maxdist => 3 ) ];
is_deeply($ret, [ ], 'Finding many stations Bxxtree fuzzy at max distance 3 should fail');

