#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 26;

use Games::Cards::ShuffleTrack;

my $deck = Games::Cards::ShuffleTrack->new();
my @original_deck = @{$deck->get_deck};

my @initial_deck = @{$deck->get_deck};

# TODO: separate overhand shuffle and running tests into two files
# TODO: test multiple runs whilst dropping on top

# running two cards on top reverses top and second cards
my ($top_card, $second_card) = $deck->find( 1, 2 );
$deck->run( 2, 'drop-top' );
is( $deck->find($top_card),    2 );
is( $deck->find($second_card), 1 );

# running two cards on top again brings the deck back to its initial position
$deck->run( 2, 'drop-top' );
is( $deck->find($top_card),    1 );
is( $deck->find($second_card), 2 );

# running one card moves it to the bottom
$deck->run( 1 );
is( $deck->find($top_card),    52 );

# running 10 cards to the bottom moves the 10th card to the -10th position
my $tenth_card = $deck->find(10);
$deck->run(10);
is( $deck->find(-10), $tenth_card);

# running no cards does nothing
my @deck = @{$deck->get_deck};
ok($deck->run);
is_deeply( \@deck, $deck->get_deck );

# running a negative number of cards does nothing
ok($deck->run( -2 ));
is_deeply( \@deck, $deck->get_deck );

# overhand shuffling changes top and bottom cards
my ($t, $b) = $deck->find( 1, -1 );
ok( $deck->overhand_shuffle );
isnt( $deck->find(  1 ), $t );
isnt( $deck->find( -1 ), $b );

# overhand shuffle accepts a parameter
ok( $deck->overhand_shuffle( 2 ) );

# running cards in an empty deck does nothing and the deck remains with no cards
my $empty_deck = Games::Cards::ShuffleTrack->new( 'empty' );
ok($empty_deck->run(3));
is($empty_deck->deck_size, 0);

# we can run several amounts at the same time
$deck->restart;
my ( $c1, $c2, $c3, $c4, $c5 ) = $deck->find( 1 .. 5 );
$deck->run( 2, 2 );

is( $deck->find( 1 ), $c5 );
is( $deck->find( -1 ), $c3 );
is( $deck->find( -2 ), $c4 );
is( $deck->find( -3 ), $c1 );
is( $deck->find( -4 ), $c2 );

# overhand shuffling 0 or negative times does nothing
$deck->restart;
my $initial_order = $deck->get_deck;
ok( $deck->overhand_shuffle( 0 ) );
is_deeply( $deck->get_deck, $initial_order );
ok( $deck->overhand_shuffle( -10 ) );
is_deeply( $deck->get_deck, $initial_order );

# final test to see if we can still restart the deck
$deck->restart;
is_deeply( $deck->get_deck, [@original_deck] );
