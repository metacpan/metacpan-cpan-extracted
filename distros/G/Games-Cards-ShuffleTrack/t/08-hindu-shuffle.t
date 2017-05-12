#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 5;

use Games::Cards::ShuffleTrack;

my $deck = Games::Cards::ShuffleTrack->new();
my @original_deck = @{$deck->get_deck};

# hindu shuffling changes top and bottom cards

my ($t, $b) = $deck->find( 1, -1 );

ok( $deck->hindu_shuffle );

isnt( $deck->find(  1 ), $t );
isnt( $deck->find( -1 ), $b );

# hindu shuffle accepts a parameter
ok( $deck->hindu_shuffle( 2 ) );

# final test to see if we can still restart the deck
$deck->restart;
is_deeply( $deck->get_deck, [@original_deck] );
