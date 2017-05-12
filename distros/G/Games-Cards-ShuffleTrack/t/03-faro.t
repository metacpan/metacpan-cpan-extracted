#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 4;

use Games::Cards::ShuffleTrack;

my $deck = Games::Cards::ShuffleTrack->new();
my @original_deck = @{$deck->get_deck};

# a deck of 52 cards after 8 faro-outs should result in the original order
$deck->faro( 'out' ) for 1 .. 8;

my @after_8_faro_outs = @{$deck->get_deck()};

is_deeply( \@after_8_faro_outs, \@original_deck );

# a deck of 52 cards after 26 faro-ins should see its order reversed
$deck->faro( 'in' ) for 1 .. 26;

my @after_26_faro_ins = @{$deck->get_deck};

is_deeply( [@after_26_faro_ins], [reverse @original_deck] );

# a deck that has been through 26 faro-ins will get to its original order with 26 more
$deck->faro( 'in' ) for 1 .. 26;

my @after_52_faro_ins = @{$deck->get_deck};

is_deeply( [@after_52_faro_ins], [@original_deck] );

# final test to see if we can still restart the deck
$deck->restart;
is_deeply( $deck->get_deck, [@original_deck] );
