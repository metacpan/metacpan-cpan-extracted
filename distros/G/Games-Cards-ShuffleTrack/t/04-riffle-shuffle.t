#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 5;

use Games::Cards::ShuffleTrack;

my $deck = Games::Cards::ShuffleTrack->new();
my @original_deck = @{$deck->get_deck};

my @before_shuffling = $deck->get_deck();
my ($bottom, $tenth_from_bottom) = $deck->find( -1, -10 );

# shuffle the deck
$deck->riffle_shuffle();

my @after_shuffling = $deck->get_deck();

# deck is now not in the same order
cmp_ok( $deck->distance( $tenth_from_bottom, $bottom ), '>', 9);

# bottom card has changed
isnt( $before_shuffling[-1], $after_shuffling[-1] );

# deck has the same amount of cards as in the beginning
is( scalar @before_shuffling, scalar @after_shuffling );

# riffle shuffling at the 26th position will leave the 27th card above the 26th
my ($card_26, $card_27) = $deck->find( 26, 27 );
$deck->riffle_shuffle( 26 );
cmp_ok( $deck->find( $card_26 ) , '>', $deck->find( $card_27 ));

# final test to see if we can still restart the deck
$deck->restart;
is_deeply( $deck->get_deck, [@original_deck] );
