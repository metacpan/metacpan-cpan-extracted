#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 57;

use Games::Cards::ShuffleTrack;

my $deck = Games::Cards::ShuffleTrack->new();
my @original_deck = @{$deck->get_deck};
my $top_card = $deck->peek( 1 );

# taking a random card decreases the deck size and the card is no longer there
$deck->restart;
my $deck_size = $deck->deck_size();
$deck->remove( 1 );
is( $deck->deck_size, $deck_size - 1 );

$deck->take_random( );
is( $deck->deck_size, $deck_size - 2 );

# taking a random card after the 13th position preserves the top 13 cards
$deck->restart;
my @top_stock;
for ( 1 .. 13 ) {
	push @top_stock, $deck->find( $_ );
}
my $random_card = $deck->take_random( 14 );

ok( not grep {/$random_card/} @top_stock );

# taking a random card after the 51st position results in the 
$deck->restart;
my $card52 = $deck->find( 52 );
is( $deck->take_random( 52 ), $card52 );

# taking a random card at a specific position results in that specific card
$deck->restart;
for ( 1 .. 52 ) {
	is( $deck->find( $_ ), $deck->take_random( $_, $_ ) );
	$deck->restart;
}

# final test to see if we can still restart the deck
$deck->restart;
is_deeply( $deck->get_deck, [@original_deck] );
