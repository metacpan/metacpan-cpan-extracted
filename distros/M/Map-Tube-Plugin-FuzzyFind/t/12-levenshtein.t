#!perl
use 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;
use lib 't/';
use Sample;

eval 'use Text::Levenshtein::XS';
if ($@) {
  eval 'use Text::Levenshtein';
  plan skip_all => 'Text::Levenshtein::XS or Text::Levenshtein required for this test' if $@;
}

plan tests => 26;

sub a2n { return [ map { $_->name( ) } @{ $_[0] } ]; }

my $tube = new_ok( 'Sample' );
my $ret;

$ret = $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'levenshtein' );
is( $ret, 'Bakerloo', 'Finding Bakerloo based on Levenshtein' );

$ret = $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'levenshtein', maxdist => 6 );
is( $ret, 'Bakerloo', 'Finding line Packalu based on Levenshtein with distance 6' );

$ret = $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'levenshtein' );
is( $ret, undef, 'Finding line Packalu based on Levenshtein with standard distance should fail' );

$ret = $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'levenshtein', maxdist => 5 );
is( $ret, undef, 'Finding line Packalu based on Levenshtein with distance 5 should fail' );

$ret = [ $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'levenshtein' ) ];
is_deeply( $ret, [ 'Bakerloo' ], 'Finding many lines Bakerloo based on Levenshtein' );

$ret = [ $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'levenshtein', maxdist => 6 ) ];
is_deeply( $ret, [ 'Bakerloo', 'Central', 'Circle', 'DLR', 'Piccadilly', 'Tunnel' ], 'Finding many lines Packalu based on Levenshtein with distance 6' );

$ret = [ $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'levenshtein', maxdist => 5 ) ];
is_deeply( $ret, [ ], 'Finding many lines Packalu based on Levenshtein with distance 5 should fail' );

$ret = [ $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'levenshtein' ) ];
is_deeply( $ret, [ ], 'Finding many lines Packalu based on Levenshtein with standard distance should fail' );

$ret = $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'levenshtein' );
ok( $ret, 'Finding Baker Street based on Levenshtein' );
is( $ret->name(), 'Baker Street', 'Finding station Baker Street based on Levenshtein' );

$ret = $tube->fuzzy_find( 'Baker', objects => 'stations', method => 'levenshtein' );
ok( $ret, 'Finding Baker based on Levenshtein' );
is( $ret->name(), 'Bank', 'Finding station Baker based on Levenshtein' );

$ret = $tube->fuzzy_find( 'Paisvatr', objects => 'stations', method => 'levenshtein' );
ok( $ret, 'Finding Paisvatr based on Levenshtein' );
is( $ret->name(), 'Bayswater', 'Finding station Paisvatr based on Levenshtein' );

$ret = $tube->fuzzy_find( 'Beisftr', objects => 'stations', method => 'levenshtein', maxdist => 6 );
ok( $ret, 'Finding Beisvtr based on Levenshtein with distance 6' );
is( $ret->name(), 'Bayswater', 'Finding station Beisftr based on Levenshtein at max distance 6' );

$ret = $tube->fuzzy_find( 'Beisftr', objects => 'stations', method => 'levenshtein' );
is( $ret, undef, 'Finding station Beisftr based on Levenshtein at standard max distance should fail' );

$ret = $tube->fuzzy_find( 'Beisftr', objects => 'stations', method => 'levenshtein', maxdist => 4 );
is( $ret, undef, 'Finding station Beisftr based on Levenshtein at max distance 4 should fail' );

$ret = [ $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'levenshtein', maxdist => 4 ) ];
is_deeply( a2n($ret), [ 'Baker Street', 'Bond Street' ], 'Finding many stations Baker Street based on Levenshtein at max distance 4' );

$ret = [ $tube->fuzzy_find( 'Baker', objects => 'stations', method => 'levenshtein' ) ];
is_deeply( a2n($ret), [ 'Bank', 'Iver' ], 'Finding many stations Baker based on Levenshtein' );

$ret = [ $tube->fuzzy_find( 'Paisvatr', objects => 'stations', method => 'levenshtein' ) ];
is_deeply( a2n($ret), [ 'Bayswater' ], 'Finding many stations Paisvatr based on Levenshtein' );

$ret = [ $tube->fuzzy_find( 'Bxxtree', objects => 'stations', method => 'levenshtein', maxdist => 4 ) ];
is_deeply( a2n($ret), [ 'Becontree' ], 'Finding many stations Bxxtree based on Levenshtein at max distance 4' );

$ret = [ $tube->fuzzy_find( 'Bxxtree', objects => 'stations', method => 'levenshtein', maxdist => 5 ) ];
is_deeply( a2n($ret), [ 'Becontree', 'Brixton', 'Bushey', 'Hoxton' ], 'Finding many stations Bxxtree based on Levenshtein at max distance 5' );

$ret = [ $tube->fuzzy_find( 'Bxxtree', objects => 'stations', method => 'levenshtein' ) ];
is_deeply( a2n($ret), [ 'Becontree' ], 'Finding many stations Bxxtree based on Levenshtein at standard max distance' );

$ret = [ $tube->fuzzy_find( 'Bxxtree', objects => 'stations', method => 'levenshtein', maxdist => 3 ) ];
is_deeply( $ret, [ ], 'Finding many stations Bxxtree based on Levenshtein at max distance 3 should fail' );

