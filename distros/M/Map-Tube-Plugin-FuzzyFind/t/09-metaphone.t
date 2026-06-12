#!perl
use 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;
use lib 't/';
use Sample;

eval 'use Text::Metaphone';
plan skip_all => 'Text::Metaphone required for this test' if $@;

# Would like to skip tests if Text::Metaphone is not installed.
# Ordinarily, this would be done like so:
#   my $loaded = eval q{use Text::Metaphone qw(); 1; };
#   plan skip_all => 'Text::Metaphone required for this test' unless $loaded;
# However, there seems to be a glitch in Text::Metaphone (in its XS code?)
# such that it will silently not be available in the module to be tested if it
# has already been referenced here in the test script. (Other modules like
# Text::Levenshtein do not seem to have this problem.)
# So we have to resort to a somewhat roundabout way to take care of this; cf. below.

plan tests => 19;

sub a2n { return [ map { $_->name( ) } @{ $_[0] } ]; }

my $tube = new_ok( 'Sample' );
my $ret;

SKIP: {
        eval { $ret = $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'metaphone' ); };
        if ( $@ =~ /Matcher module .* not loaded/ ) {
          diag 'Text::Metaphone required for this test -- skipping';
          skip 'Text::Metaphone required for this test', 14;
        }

        is( $ret, 'Bakerloo', 'Finding line Bakerloo based on Metaphone' );

        $ret = $tube->fuzzy_find( 'Bkrl', objects => 'lines', method => 'metaphone' );
        is( $ret, 'Bakerloo', 'Finding line Bkrl based on Metaphone' );

        $ret = $tube->fuzzy_find( 'Bxqxq', objects => 'lines', method => 'metaphone' );
        is( $ret, undef, 'Finding line Bxqxq based on Metaphone' );

        $ret = [ $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'metaphone' ) ];
        is_deeply( $ret, [ 'Bakerloo' ], 'Finding many lines Bakerloo based on Metaphone' );

        $ret = [ $tube->fuzzy_find( 'Bkrl', objects => 'lines', method => 'metaphone' ) ];
        is_deeply( $ret, [ 'Bakerloo' ], 'Finding many lines Bkrl based on Metaphone' );

        $ret = [ $tube->fuzzy_find( 'Bxqxq', objects => 'lines', method => 'metaphone' ) ];
        is_deeply( $ret, [ ], 'Finding many lines Bxqxq based on Metaphone' );

        $ret = $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'metaphone' );
        ok( $ret, 'Finding station Baker Street based on Metaphone' );
        is( $ret->name(), 'Baker Street', 'Finding station Baker Street based on Metaphone' );

        $ret = $tube->fuzzy_find( 'Bkrstrt', objects => 'stations', method => 'metaphone' );
        ok( $ret, 'Finding station Bkrstrt based on Metaphone' );
        is( $ret->name(), 'Baker Street', 'Finding station Bkrstrt based on Metaphone' );

        $ret = $tube->fuzzy_find( 'Bkrstrx', objects => 'stations', method => 'metaphone' );
        ok( $ret, 'Finding station Bkrstrx based on Metaphone' );
        is( $ret->name(), 'Baker Street', 'Finding station Bkrstrx based on Metaphone' );

        $ret = $tube->fuzzy_find( 'Bkrstrx', objects => 'stations', method => 'metaphone', maxcodelen => 8 );
        is( $ret, undef, 'Finding station Bkrstrx based on Metaphone at maxcodelen=8' );

        $ret = $tube->fuzzy_find( 'Bkrstrx', objects => 'stations', method => 'metaphone', maxcodelen => 0 );
        is( $ret, undef, 'Finding station Bkrstrx based on Metaphone at maxcodelen=0' );

        $ret = $tube->fuzzy_find( 'Bxqxq', objects => 'stations', method => 'metaphone' );
        is( $ret, undef, 'Finding station Bxqxq based on Metaphone' );

        $ret = [ $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'metaphone' ) ];
        is_deeply( a2n($ret), [ 'Baker Street' ], 'Finding many stations Baker Street based on Metaphone' );

        $ret = [ $tube->fuzzy_find( 'Bkrstrt', objects => 'stations', method => 'metaphone' ) ];
        is_deeply( a2n($ret), [ 'Baker Street' ], 'Finding many stations Bkrstrt based on Metaphone' );

        $ret = [ $tube->fuzzy_find( 'Bxqxq', objects => 'stations', method => 'metaphone' ) ];
        is_deeply( $ret, [ ], 'Finding many stations Bxqxq based on Metaphone' );
}
