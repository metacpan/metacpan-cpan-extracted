#!/usr/bin/perl -w

use strict;
use Games::Cards::ShuffleTrack;

###                                             ###
### This is a demonstration of riffle shuffling ###
###   (it stops when the AS gets to the top)    ###
###                                             ###

my $deck = Games::Cards::ShuffleTrack->new;
my $shuffles = 0;
until ( $deck->find( "AS") == 1 ) {
    $shuffles++;
    $deck->riffle_shuffle;
    print "$shuffles: @{$deck->get_deck}\n";
}

print "It took $shuffles random riffle shuffles to take the Ace of Spades to the top.\n";

