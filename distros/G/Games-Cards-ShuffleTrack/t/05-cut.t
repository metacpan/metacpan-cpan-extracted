#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 44;

use Games::Cards::ShuffleTrack;

my $deck = Games::Cards::ShuffleTrack->new();
my @original_deck = @{$deck->get_deck};
my $pile = Games::Cards::ShuffleTrack->new( 'empty' );
my @original_pile = @{$pile->get_deck};

# cutting 26 twice results in the original order
my $deck_1 = $deck->get_deck;
$deck->cut(26) for 1 .. 2;
is_deeply( $deck_1, $deck->get_deck );

# cutting 13 four times results in the original order
$deck->cut(13) for 1 .. 4;
is_deeply( $deck_1, $deck->get_deck );

# cutting one card moves it to the bottom
my ($top_card, $second_card) = @original_deck[0, 1];
$deck->restart;
$deck->cut(1);

my @cut_deck = @{$deck->get_deck};
my ($new_top_card, $new_bottom_card) = @cut_deck[0, -1];

is( $top_card, $new_bottom_card);
is( $second_card, $new_top_card);

# relative position of cards (as long as they're kept in the same packet) is the same
my $distance = $deck->distance( '3H', 'KH' );
$deck->cut(26);
is( $deck->distance( '3H', 'KH' ), $distance );

# cut the deck normally changes top and bottom cards
my @before_cutting = $deck->get_deck();

$deck->cut();

my @after_cutting = $deck->get_deck();

isnt( $before_cutting[0], $after_cutting[0] );
isnt( $before_cutting[-1], $after_cutting[-1] );

# cutting above a card moves it to the top_card
for my $card ( qw/AS JS 10H/ ) {
	$deck->cut_above( $card );
	is( $deck->find( $card ), 1 );
}

# cutting below a card moves it to te bottom
for my $card ( qw/AS JS 10H/ ) {
	$deck->cut_below( $card );
	is( $deck->find( $card ), 52 );
}

# cutting above a card that is already on top doesn't do anything
$deck->cut_above( 'JS' );
is( $deck->find( 'JS' ), 1 );
$deck->cut_above( 'JS' );
is( $deck->find( 'JS' ), 1 );

# cutting below a card that is already on the bottom doesn't do anything
$deck->cut_below( 'JS' );
is( $deck->find( 'JS' ), 52 );
$deck->cut_below( 'JS' );
is( $deck->find( 'JS' ), 52 );

# additional ways of cutting also work
ok( $deck->cut( 'short'  ) );
ok( $deck->cut( 'center' ) );
ok( $deck->cut( 'deep'   ) );

# cutting at the top or bottom of the deck doesn't do anything
my $deck_before_cutting = $deck->get_deck;
$deck->cut( 0 );
is_deeply( $deck_before_cutting, $deck->get_deck );
$deck->cut( 52 );
is_deeply( $deck_before_cutting, $deck->get_deck );
$deck->cut( -52 );
is_deeply( $deck_before_cutting, $deck->get_deck );

# test cut_to
$deck->restart;
$pile->restart;
$deck->cut_to( $pile, 10 );
is( $deck->deck_size, 42 );
is( $pile->deck_size, 10 );

$deck->cut_to( $pile, 1, 5 );
cmp_ok( $deck->deck_size, '<', 42 );
cmp_ok( $deck->deck_size, '>', 36 );
cmp_ok( $pile->deck_size, '>', 10 );
cmp_ok( $pile->deck_size, '<', 16 );

$deck->restart;
$pile->restart;
$deck->cut_to( $pile, 12 );
is( $deck->deck_size, 40 );
is( $pile->deck_size, 12 );

# cut_to is able to create new piles
$deck->restart;
my $hand = $deck->cut_to( 5 );
is( ref($hand), 'Games::Cards::ShuffleTrack' );
is( $deck->deck_size, 47);
is( $hand->deck_size, 5 );

$deck->restart;
my $new_location = $deck->cut_to();
cmp_ok( $new_location->deck_size, '>', 0 );
cmp_ok( $deck->deck_size, '>', 0 );
is( $new_location->deck_size + $deck->deck_size, 52 );

# test place_on_top
$deck->restart;
$deck->place_on_top( 'Joker' );
is( $deck->find( 'Joker' ), 1 );
is( $deck->deck_size, 53 );

# complete a cut and move_to
$deck->restart;
$pile->restart;
$deck->cut_to( $pile );
$deck->move_to( $pile );
is( $deck->deck_size, 0 );
is( $pile->deck_size, 52 );
$pile->cut_above( 'AH' );
$deck->restart;
is_deeply( $deck->get_deck, $pile->get_deck );

# final test to see if we can still restart the deck
$deck->restart;
is_deeply( $deck->get_deck, [@original_deck] );
$pile->restart;
is_deeply( $pile->get_deck, [@original_pile] );
