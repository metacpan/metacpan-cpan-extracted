#!/usr/bin/perl -w

use strict;
use Games::Cards::ShuffleTrack;

###                                                ###
### This is a demonstration of 8 faro out shuffles ###
###                                                ###

my $deck = Games::Cards::ShuffleTrack->new;

print "0: @{$deck->get_deck}\n";
for ( 1 .. 8 ) {
    $deck->faro( 'out' );
    print "$_: @{$deck->get_deck}\n";
}
