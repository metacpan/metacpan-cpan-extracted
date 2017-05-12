#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 21;

use Games::Cards::ShuffleTrack;

my $deck = Games::Cards::ShuffleTrack->new();
my @original_deck = @{$deck->get_deck};

# AH is first card
is( $deck->find('AH'), 1 );

# First card is AH
is( $deck->find( 1 ), 'AH' );

# Negative numbers
is( $deck->find( -1 ), 'AS' );

# AH is first card and AS is last card
is_deeply( [$deck->find( 1, 52 )], ['AH', 'AS'] );
is_deeply( [$deck->find( 'AH', 'AS' )], [1, 52] );

# 2H is 1 card away from AH
is( $deck->distance( 'AH', '2H' ), 1 );

# AH is -1 card away from 2H
is( $deck->distance( '2H', 'AH' ), -1 );

# AS is 51 cards away from AH
is( $deck->distance( 'AH', 'AS' ), 51 );

# distance between first and tenth cards is 9
is( $deck->distance( $deck->find( 1, 10 ) ), 9 );

# 2H comes after AH
is( $deck->find_card_after(  'AH' ), '2H' );
# AH comes before 2H
is( $deck->find_card_before( '2H' ), 'AH' );


# Card before AH is AS (card before the first one is the last)
is( $deck->find_card_before( 'AH' ), 0 );
# Card after AS is AH (card after last is the first one)
is( $deck->find_card_after(  'AS' ), 0 );


# managing errors
is_deeply( [$deck->find( )], [] );
is( $deck->find( 0 ), q{} );
is( $deck->find( 100 ), q{} );
is_deeply( [$deck->find( 0, 100 )], [ (q{}, q{}) ] );
is_deeply( [$deck->find( 'no such card' )], [ 0 ] );

# can get card 52 but not 53
ok( $deck->find( 52 ) );
is_deeply( [$deck->find( 53 )], [ q{} ] );

# final test to see if we can still restart the deck
$deck->restart;
is_deeply( $deck->get_deck, [@original_deck] );
