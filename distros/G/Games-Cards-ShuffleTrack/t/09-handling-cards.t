#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 3;

use Games::Cards::ShuffleTrack;

my $deck = Games::Cards::ShuffleTrack->new();
my @original_deck = @{$deck->get_deck};
my $top_card = $deck->peek( 1 );

# putting a card on top of the deck increases its size and the card gets added on top
$deck->put( 'Joker' );
is( $deck->deck_size, 53 );
is( $deck->find( 'Joker' ), 1 );

# final test to see if we can still restart the deck
$deck->restart;
is_deeply( $deck->get_deck, [@original_deck] );
