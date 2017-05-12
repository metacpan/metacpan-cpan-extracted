#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 15;

use Games::Cards::ShuffleTrack;

my $deck = Games::Cards::ShuffleTrack->new();
my @original_deck = @{$deck->get_deck};

# removing Jokers there aren't there don't alter the deck
$deck->restart;
$deck->remove_all( 'Joker' );
ok( $deck->is_original );

# removing a suit
$deck->restart;
$deck->remove_all( 'C' );
is( $deck->count( 'C' ), 0 );
is( $deck->count( 'A' ), 3 );
is( $deck->size, 39 );

# removing a four-of-a-kind
$deck->restart;
$deck->remove_all( 'A' );
is( $deck->count( 'S' ), 12 );
is( $deck->size, 48 );

# removing a suit and a value
$deck->restart;
$deck->remove_all( 'A', 'C' );
is( $deck->size, 36 );
is( $deck->count( 'C' ), 0 );
is( $deck->count( 'H' ), 12 );
is( $deck->count( 'S' ), 12 );
is( $deck->count( 'D' ), 12 );

# removing everything
$deck->restart;
$deck->remove_all;
is( $deck->size, 0 );

# adding a card and removing it
$deck->restart;
$deck->put( 'Joker' );
$deck->remove_all( 'Joker' );
ok( $deck->is_original );
$deck->put( 'Joker' );
$deck->put( 'Joker' );
$deck->remove_all( 'Joker' );
ok( $deck->is_original );

# final test to see if we can still restart the deck
$deck->restart;
is_deeply( $deck->get_deck, [@original_deck] );
