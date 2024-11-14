#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;

eval 'use Map::Tube::London 1.39';
plan skip_all => 'Map::Tube::London (>= 1.39) required for this test' if $@;

plan tests => 16;

sub a2n { return [ map { $_->name( ) } @{ $_[0] } ]; }

my $tube = new_ok( 'Map::Tube::London' );
my $ret;

SKIP: {
        eval { $ret = $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'doublemetaphone' ); };
        if ( $@ =~ /Matcher module .* not loaded/ ) {
          diag 'Text::Metaphone required for this test -- skipping';
          skip 'Text::Metaphone required for this test', 14;
        }

        is( $ret, 'Bakerloo', 'Finding line Bakerloo based on DoubleMetaphone' );

        $ret = $tube->fuzzy_find( 'Bkrl', objects => 'lines', method => 'doublemetaphone' );
        is( $ret, 'Bakerloo', 'Finding line Bkrl based on DoubleMetaphone' );

        $ret = $tube->fuzzy_find( 'Bxqxq', objects => 'lines', method => 'doublemetaphone' );
        is( $ret, undef, 'Finding line Bxqxq based on DoubleMetaphone' );

        $ret = $tube->fuzzy_find( 'Able', objects => 'lines', method => 'doublemetaphone' );
        is( $ret, 'Jubilee', 'Finding line Able based on alternate encoding by DoubleMetaphone' );

        $ret = [ $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'doublemetaphone' ) ];
        is_deeply( $ret, [ 'Bakerloo' ], 'Finding many lines Bakerloo based on DoubleMetaphone' );

        $ret = [ $tube->fuzzy_find( 'Bkrl', objects => 'lines', method => 'doublemetaphone' ) ];
        is_deeply( $ret, [ 'Bakerloo' ], 'Finding many lines Bkrl based on DoubleMetaphone' );

        $ret = [ $tube->fuzzy_find( 'Bxqxq', objects => 'lines', method => 'doublemetaphone' ) ];
        is_deeply( $ret, [ ], 'Finding many lines Bxqxq based on DoubleMetaphone' );

        $ret = $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'doublemetaphone' );
        ok( $ret, 'Finding station Baker Street based on DoubleMetaphone' );
        is( $ret->name(), 'Baker Street', 'Finding station Baker Street based on DoubleMetaphone' );

        $ret = $tube->fuzzy_find( 'Bkrstrt', objects => 'stations', method => 'doublemetaphone' );
        ok( $ret, 'Finding station Bkrstrt based on DoubleMetaphone' );
        is( $ret->name(), 'Baker Street', 'Finding station Bkrstrt based on DoubleMetaphone' );

        $ret = $tube->fuzzy_find( 'Bxqxq', objects => 'stations', method => 'doublemetaphone' );
        is( $ret, undef, 'Finding station Bxqxq based on DoubleMetaphone' );

        $ret = [ $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'doublemetaphone' ) ];
        is_deeply( a2n($ret), [ 'Baker Street', 'Buckhurst Hill' ], 'Finding many stations Baker Street based on DoubleMetaphone' );

        $ret = [ $tube->fuzzy_find( 'Bkrstrt', objects => 'stations', method => 'doublemetaphone' ) ];
        is_deeply( a2n($ret), [ 'Baker Street', 'Buckhurst Hill' ], 'Finding many stations Bkrstrt based on DoubleMetaphone' );

        $ret = [ $tube->fuzzy_find( 'Bxqxq', objects => 'stations', method => 'doublemetaphone' ) ];
        is_deeply( $ret, [ ], 'Finding many stations Bxqxq based on DoubleMetaphone' );
}
