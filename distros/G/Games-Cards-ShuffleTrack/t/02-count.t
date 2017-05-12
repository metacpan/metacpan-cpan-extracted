#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 34;

use Games::Cards::ShuffleTrack;

my $deck = Games::Cards::ShuffleTrack->new();
my @original_deck = @{$deck->get_deck};

# non existing cards don't exist
is( $deck->count( 'Joker' ), 0 );

# counting non existing cards in wantarray format
is_deeply( [$deck->count( 'Joker', 'H' )], [0, 13] );

# deck has 13 of each suit
is( $deck->count( 'C' ), 13 );
is( $deck->count( 'H' ), 13 );
is( $deck->count( 'S' ), 13 );
is( $deck->count( 'D' ), 13 );

# deck has 4 of each value
for (qw/A 2 3 4 5 6 7 8 9 10 J Q K/) {
	is( $deck->count( $_ ), 4 );
}

# deck has no Jokers
is( $deck->count( 'Joker' ), 0 );

# adding a Joker to the deck result in a deck with one Joker
$deck->put( 'Joker' );
is( $deck->count( 'Joker' ), 1 );

# counting two suits results in 26 cards
is( $deck->count( 'C', 'S' ), 26 );

# counting three values results in 12 cards
is( $deck->count( 2, 4, 'K' ), 12 );

# counting a suit twice results in only 13 cards
is( $deck->count( 'C', 'C' ), 13 );
# unless you're expecting two separate values
is_deeply( [$deck->count( 'C', 'C' )], [13, 13] );
is_deeply( [$deck->count( 'C', 3 ) ], [ 13, 4 ] );

# counting a suit and a value results in 16, not 17 (as the card of that value and suit is not counted twice)
is( $deck->count( 'C', 10 ), 16);

# adding a repeated card to the deck and looking for it still works
$deck->put( 'Joker' );
is( $deck->count( 'Joker' ), 2 );

# adding a signed joker will take the amount of Jokers up to three
$deck->put( 'Signed Joker' );
is( $deck->count( 'Joker' ), 3 );

# same thing for signed cards
$deck->put( 'Signed 4C' );
is( $deck->count( '4' ), 5 );
is( $deck->count( 'C' ), 14 );
is( $deck->count( '4C' ), 2 );

# behaviour of wantarray with just one search
my @results = $deck->count( 'H' );
is( $results[0], 13 );

# final test to see if we can still restart the deck
$deck->restart;
is_deeply( $deck->get_deck, [@original_deck] );
