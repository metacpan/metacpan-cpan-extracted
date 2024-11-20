#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;

eval 'use Map::Tube 3.77';
plan skip_all => 'Map::Tube (>= 3.77) required for this test' if $@;
eval 'use Map::Tube::London 1.39';
plan skip_all => 'Map::Tube::London (>= 1.39) required for this test' if $@;
eval 'use Text::Levenshtein::Damerau::XS';
if ($@) {
  eval 'use Text::Levenshtein::Damerau';
  plan skip_all => 'Text::Levenshtein::Damerau::XS or Text::Levenshtein::Damerau required for this test' if $@;
}

plan tests => 26;

sub a2n { return [ map { $_->name( ) } @{ $_[0] } ]; }

my $tube = new_ok( 'Map::Tube::London' );
my $ret;

$ret = $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'levenshteindamerau' );
is( $ret, 'Bakerloo', 'Finding Bakerloo based on Levenshtein-Damerau' );

$ret = $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'levenshteindamerau', maxdist => 6 );
is( $ret, 'Bakerloo', 'Finding line Packalu based on Levenshtein-Damerau with distance 6' );

$ret = $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'levenshteindamerau' );
is( $ret, undef, 'Finding line Packalu based on Levenshtein-Damerau with standard distance should fail' );

$ret = $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'levenshteindamerau', maxdist => 5 );
is( $ret, undef, 'Finding line Packalu based on Levenshtein-Damerau with distance 5 should fail' );

$ret = [ $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'levenshteindamerau' ) ];
is_deeply($ret, [ 'Bakerloo' ], 'Finding many lines Bakerloo based on Levenshtein-Damerau');

$ret = [ $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'levenshteindamerau', maxdist => 6 ) ];
is_deeply( $ret, [ 'Bakerloo', 'Central', 'Circle', 'DLR', 'Piccadilly', 'Tunnel' ], 'Finding many lines Packalu based on Levenshtein-Damerau with distance 6' );

$ret = [ $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'levenshteindamerau', maxdist => 5 ) ];
is_deeply( $ret, [ ], 'Finding many lines Packalu based on Levenshtein-Damerau with distance 5 should fail' );

$ret = [ $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'levenshteindamerau' ) ];
is_deeply( $ret, [ ], 'Finding many lines Packalu based on Levenshtein-Damerau with standard distance should fail' );

$ret = $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'levenshteindamerau' );
ok( $ret, 'Finding Baker Street based on Levenshtein-Damerau' );
is( $ret->name(), 'Baker Street', 'Finding station Baker Street based on Levenshtein-Damerau' );

$ret = $tube->fuzzy_find( 'Baker', objects => 'stations', method => 'levenshteindamerau' );
ok( $ret, 'Finding Baker based on Levenshtein-Damerau' );
is( $ret->name(), 'Bank', 'Finding station Baker based on Levenshtein-Damerau' );

$ret = $tube->fuzzy_find( 'Paisvatr', objects => 'stations', method => 'levenshteindamerau' );
ok( $ret, 'Finding Paisvatr based on Levenshtein-Damerau' );
is( $ret->name(), 'Bayswater', 'Finding station Paisvatr based on Levenshtein-Damerau' );

$ret = $tube->fuzzy_find( 'Beisftr', objects => 'stations', method => 'levenshteindamerau', maxdist => 6 );
ok( $ret, 'Finding Beisvtr based on Levenshtein-Damerau with distance 6' );
is( $ret->name(), 'Bayswater', 'Finding station Beisftr based on Levenshtein-Damerau at max distance 6' );

$ret = $tube->fuzzy_find( 'Beisftr', objects => 'stations', method => 'levenshteindamerau' );
is( $ret, undef, 'Finding station Beisftr based on Levenshtein-Damerau at standard max distance should fail' );

$ret = $tube->fuzzy_find( 'Beisftr', objects => 'stations', method => 'levenshteindamerau', maxdist => 4 );
is( $ret, undef, 'Finding station Beisftr based on Levenshtein-Damerau at max distance 4 should fail' );

$ret = [ $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'levenshteindamerau', maxdist => 4 ) ];
is_deeply( a2n($ret), [ 'Baker Street', 'Bond Street' ], 'Finding many stations Baker Street based on Levenshtein-Damerau at max distance 4' );

$ret = [ $tube->fuzzy_find( 'Baker', objects => 'stations', method => 'levenshteindamerau' ) ];
is_deeply( a2n($ret), [ 'Bank', 'Iver' ], 'Finding many stations Baker based on Levenshtein-Damerau' );

$ret = [ $tube->fuzzy_find( 'Paisvatr', objects => 'stations', method => 'levenshteindamerau' ) ];
is_deeply( a2n($ret), [ 'Bayswater' ], 'Finding many stations Paisvatr based on Levenshtein-Damerau' );

$ret = [ $tube->fuzzy_find( 'Bxxtree', objects => 'stations', method => 'levenshteindamerau', maxdist => 4 ) ];
is_deeply( a2n($ret), [ 'Becontree' ], 'Finding many stations Bxxtree based on Levenshtein-Damerau at max distance 4' );

$ret = [ $tube->fuzzy_find( 'Bxxtree', objects => 'stations', method => 'levenshteindamerau', maxdist => 5 ) ];
is_deeply( a2n($ret), [ 'Becontree', 'Brixton', 'Bushey', 'Hoxton' ], 'Finding many stations Bxxtree based on Levenshtein-Damerau at max distance 5' );

$ret = [ $tube->fuzzy_find( 'Bxxtree', objects => 'stations', method => 'levenshteindamerau' ) ];
is_deeply( a2n($ret), [ 'Becontree' ], 'Finding many stations Bxxtree based on Levenshtein-Damerau at standard max distance' );

$ret = [ $tube->fuzzy_find( 'Bxxtree', objects => 'stations', method => 'levenshteindamerau', maxdist => 3 ) ];
is_deeply( $ret, [ ], 'Finding many stations Bxxtree based on Levenshtein-Damerau at max distance 3 should fail' );

