#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 13;

use Games::Cards::ShuffleTrack;

my $deck = Games::Cards::ShuffleTrack->new();
my @original_deck = @{$deck->get_deck};
my $top_card = $deck->peek( 1 );
my $bottom_card = $deck->peek( -1 );

# inserting cards in the deck
$deck->restart;
is( $deck->find( 'Joker' ), 0 );
$deck->insert(   'Joker',   10 );
is( $deck->find( 'Joker' ), 10 );

# inserting at position 1 places the card on top of the deck
$deck->restart;
is( $deck->find( 'Joker' ), 0 );
$deck->insert(   'Joker',   1 );
is( $deck->find( 'Joker' ), 1 );

# inserting at a non-existing position places the card on the bottom of the deck
$deck->restart;
is( $deck->find( 'Joker' ), 0 );
$deck->insert(   'Joker',   100 );
is( $deck->find( 'Joker' ), 53 );

# inserting at a random position also places the card in the deck
$deck->restart;
is( $deck->find( 'Joker' ), 0 );
$deck->insert(   'Joker' );
cmp_ok( $deck->find( 'Joker' ), '>', 0 );

# inserting at the last position shifts the last card
$deck->restart;
$deck->insert( 'Joker', 52 );
is( $deck->find( 'Joker' ), 52 );
is( $deck->find( 53 ), $bottom_card );

# inserting at negative positions works
$deck->restart;
$deck->insert( 'Joker', -1 );
is( $deck->peek( -1 ), 'Joker' );

$deck->restart;
$deck->insert( 'Joker', -52 );
is( $deck->peek( 2 ), 'Joker' );

# final test to see if we can still restart the deck
$deck->restart;
is_deeply( $deck->get_deck, [@original_deck] );
