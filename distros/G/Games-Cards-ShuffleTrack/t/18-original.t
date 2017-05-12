#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 14;

use Games::Cards::ShuffleTrack;

my $deck = Games::Cards::ShuffleTrack->new();
my $pile = Games::Cards::ShuffleTrack->new( 'empty' );
my @original_deck = @{$deck->get_deck};

# new deck is is_original
ok( $deck->is_original );
ok( $pile->is_original );

# cut deck is not original
$deck->restart;
$deck->cut;
ok( not $deck->is_original );

$deck->restart;
$deck->running_cuts;
ok( not $deck->is_original );

# shuffled deck is not original
$deck->restart;
$deck->riffle_shuffle;
ok( not $deck->is_original );

$deck->restart;
$deck->hindu_shuffle;
ok( not $deck->is_original );

$deck->restart;
$deck->overhand_shuffle;
ok( not $deck->is_original );

# deck with an extra card is not original
$deck->restart;
$deck->put( 'Joker' );
ok( not $deck->is_original );

# deck without a card is not original
$deck->restart;
$deck->take_random;
ok( not $deck->is_original );

# restarted deck is original
$deck->restart;
ok( $deck->is_original );

# empty pile remains original even it is shuffled
$pile->riffle_shuffle;
ok( $pile->is_original );

# changing the orientation changes the deck
$deck->restart;
$deck->turn;
ok( not $deck->is_original );

# a turned pile is still in its original state
$pile->restart;
$pile->turn;
ok( $pile->is_original );

# final test to see if we can still restart the deck
$deck->restart;
is_deeply( $deck->get_deck, [@original_deck] );
