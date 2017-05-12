#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 126;

use Games::Cards::ShuffleTrack;

my $deck = Games::Cards::ShuffleTrack->new();
my @original_deck = @{$deck->get_deck};
my ($top_card, $bottom_card) = $deck->find( 1, -1 );

# $deck is a deck
isa_ok( $deck, 'Games::Cards::ShuffleTrack');

# deck has 52 cards
is( $deck->deck_size(),   52 );
is( $deck->size(),        52 );
is( $deck->original_size, 52 );

# adding cards increases deck size
$deck->put( 'Joker' );
cmp_ok( $deck->size, '>', $deck->original_size );

# removing cards decreases deck size
$deck->restart;
$deck->take_random;
cmp_ok( $deck->size, '<', $deck->original_size );
$deck->restart;
is( $deck->size, $deck->original_size );

# deck is face down
is( $deck->orientation, 'down' );

# turning the deck face up results in a face up deck and the original top and bottom cards are now reversed
$deck->restart;
ok( $deck->turn );
is( $deck->orientation, 'up' );

is( $deck->find( $top_card ),    52 );
is( $deck->find( $bottom_card ), 1  );

ok( $deck->turn );
is( $deck->orientation, 'down' );

# deck has 52 cards
is( scalar @{$deck->get_deck()}, 52);

# all cards are different (only one of each card)
my $cards;
for my $card ( @{$deck->get_deck()} ) {
	$cards->{$card}++;
};

for my $card (keys %$cards) {
	is($cards->{$card}, 1);
};

# fournier and new_deck_order share the order of diamonds
$deck->restart;
my $fournier = Games::Cards::ShuffleTrack->new('fournier');

for ( 27 .. 39 ) {
	is( $deck->find( $_ ), $fournier->find( $_ ) );
}

# fournier and new_deck_order don't share the order of hearts, spades and clubs
for ( 1 .. 26, 40 .. 52 ) {
	isnt( $deck->find( $_ ), $fournier->find( $_ ) );
}

# empty deck doesn't have cards
my $empty_deck = Games::Cards::ShuffleTrack->new( 'empty' );
is_deeply( $empty_deck->get_deck, [] );

# restarting an empty deck results in an empty deck
$empty_deck->restart;
is_deeply( $empty_deck->get_deck, [] );

# reseting a shuffled deck that started with new_deck order results in a deck in new deck order
my $other_new_deck = Games::Cards::ShuffleTrack->new;

$deck->riffle_shuffle;
$deck->riffle_shuffle;
$deck->restart;
is_deeply( $deck->get_deck, $other_new_deck->get_deck );
$deck->riffle_shuffle;
$deck->restart;
is_deeply( $deck->get_deck, $other_new_deck->get_deck );

# creating a pile with just 4 cards works well
my $pile = Games::Cards::ShuffleTrack->new( [qw/AC AH AS AD/] );
is( $pile->deck_size, 4 );
is( $pile->find( 1 ), 'AC' );

# final test to see if we can still restart the deck
$deck->restart;
is_deeply( $deck->get_deck, [@original_deck] );
