#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 45;

use Games::Cards::ShuffleTrack;

my $deck = Games::Cards::ShuffleTrack->new();
my @original_deck = @{$deck->get_deck};
my $top_card = $deck->peek( 1 );

# dealing a card from the top of the deck decreases its size
my $card = $deck->deal();
is( $card, $top_card );
is( $deck->deck_size, 51 );

# dealing from a non existing position defaults to the top of the deck (also document this behavior)
$deck->restart;
$top_card = $deck->peek( 1 );

$card  = $deck->deal( 'nowhere' );

is( $card, $top_card );
is( $deck->deck_size, 51 );

# dealing from special positions deals the right cards
for ( [ 1, 'top' ], [ 2, 'second' ], [ -2, 'greek' ], [ -1, 'bottom' ] ) {
    $card = $deck->find( $_->[0] );
    is( $deck->deal( $_->[1] ), $card );
}

# dealing a card to a pile is possible
$deck->restart;
my $pile = Games::Cards::ShuffleTrack->new( 'empty' );

$top_card = $deck->find( 1 );

$deck->deal( $pile );
is( $deck->deck_size, 51 );
is( $pile->deck_size,  1 );
is( $pile->find( 1 ), $top_card );

# dealing a card to a pile works, regardless of the type of deal
for ( [ 1, 'top' ], [ 2, 'second' ], [ -2, 'greek' ], [ -1, 'bottom' ] ) {
    $pile->restart;
    $deck->restart;
    $card = $deck->find( $_->[0] );
    $deck->deal( $_->[1], $pile );

    is( $deck->deck_size, 51 );
    is( $pile->deck_size,  1 );
    is( $pile->find( 1 ), $card );

    $pile->restart;
    $deck->restart;
    $card = $deck->find( $_->[0] );
    $deck->deal( $pile, $_->[1] );

    is( $deck->deck_size, 51 );
    is( $pile->deck_size,  1 );
    is( $pile->find( 1 ), $card );
}

# dealing from a pile onto itself does nothing
$deck->restart;
$top_card = $deck->peek( 1 );
$deck->deal( $deck );
is( $deck->deck_size, 52 );
is( $deck->peek( 1 ), $top_card );

# bottom dealing to the top is the same as double uppercut
$deck->restart;
$top_card = $deck->peek( 1 );
my $bottom_card = $deck->peek( -1 );
$deck->deal( 'bottom', $deck );
is( $deck->deck_size, 52 );
is( $deck->peek( 1 ), $bottom_card );
is( $deck->peek( 2 ), $top_card );

# deal from an empty deck does nothing (to both the deck and the destination pile)
$deck->restart;
$pile->restart;
$pile->deal( $deck );
is( $pile->size, 0  );
is( $deck->size, 52 );

# dealing from an empty deck still creates an empty deck
$pile->restart;
my $empty_pile = $pile->deal;
isa_ok( $empty_pile, 'Games::Cards::ShuffleTrack' );
is( $empty_pile->size, 0 );

# final test to see if we can still restart the deck
$deck->restart;
is_deeply( $deck->get_deck, [@original_deck] );
