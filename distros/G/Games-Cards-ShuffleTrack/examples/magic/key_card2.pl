#!/usr/bin/perl -w

use strict;

use Games::Cards::ShuffleTrack;

###                                                ###
### This is a demonstration of a simple card trick ###
###                                                ###

# shuffle the deck
my $deck = Games::Cards::ShuffleTrack->new();
$deck->riffle_shuffle() for 1 .. 4;
$deck->cut;

# offer a free selection
my $selected_card = $deck->take_random();
print "The selected card is the $selected_card.\n";

# peek the bottom card
my $key_card      = $deck->peek( -1 ); # peek the bottom card

# cut the deck to the table burying the card with the key card on top
my $table = $deck->cut_to();
$table->put( $selected_card );
$deck->complete_cut( $table );

# spread the deck and find the card immediately after the key card
print "Your card is the " . $table->find_card_after( $key_card ) . "!\n";
