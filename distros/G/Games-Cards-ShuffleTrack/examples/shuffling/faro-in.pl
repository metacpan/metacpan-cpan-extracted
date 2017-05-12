#!/usr/bin/perl -w

use strict;
use Games::Cards::ShuffleTrack;

###                                                ###
### This is a demonstration of 52 faro in shuffles ###
###                                                ###

my $deck = Games::Cards::ShuffleTrack->new;

print "0: @{$deck->get_deck}\n";
for ( 1 .. 52 ) {
    $deck->faro( 'in' );
    print "$_: @{$deck->get_deck}\n";
}
