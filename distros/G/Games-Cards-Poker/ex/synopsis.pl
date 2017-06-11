#!/usr/bin/perl
use strict;use warnings;use Games::Cards::Poker; # deal hands
my $players   =  4; # number of players to get hands dealt
my $hand_size =  5; # number of cards to deal to each player
my @hands     = (); # player hand data as array of arrayrefs
my @deck      = Shuffle(Deck()); # initially shuffled card deck
while (         $players--) { # load and print cards and scores
  push(@{$hands[$players]}, pop(@deck)) for(1 .. $hand_size );
  printf("Player$players score:%4d hand:@{$hands[$players]}\n",
                              HandScore(@{$hands[$players]})); }
