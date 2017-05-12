#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 3;

use Games::Cards::ShuffleTrack;

my $deck = Games::Cards::ShuffleTrack->new();
my @original_deck = @{$deck->get_deck};
my $pile = Games::Cards::ShuffleTrack->new( 'empty' );
my $top_card;
my @top_pile;

# bury 1 under 13
$top_card = $deck->find( 1 );
$deck->bury( 1, 13 );
is( $deck->peek( 14 ), $top_card );

# bury 13 under 1
$deck->restart;
$top_card = $deck->find( 1 );
@top_pile = $deck->find( 1 .. 13 );
$deck->bury( 13, 1 );
is_deeply( [$deck->find( 2 .. 14 )] , [@top_pile] );

# final test to see if we can still restart the deck
$deck->restart;
is_deeply( $deck->get_deck, [@original_deck] );
