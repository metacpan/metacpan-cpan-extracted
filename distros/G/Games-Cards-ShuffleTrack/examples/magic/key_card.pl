#!/usr/bin/perl -w

use strict;

use Games::Cards::ShuffleTrack;

###                                                ###
### This is a demonstration of a simple card trick ###
###                                                ###

my $deck = Games::Cards::ShuffleTrack->new();
$deck->riffle_shuffle() for 1 .. 4;

my $selected_card = $deck->take_random();
print "The selected card is the $selected_card.\n";

my $key_card      = $deck->peek( -1 ); # peek the bottom card

$deck->put( $selected_card );
$deck->cut;

print "Your card is the " . $deck->find_card_after( $key_card ) . "!\n";
