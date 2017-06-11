#!/usr/bin/perl
use strict;use warnings;use v5.10;use Games::Cards::Poker qw(:blak);
# Deal players hands and score them against dealer in position 0...
my $rounds    = shift(@ARGV) || 3; # number of rounds to run through
my $players   = shift(@ARGV) || 4; # number of players (including dealer)
my $shoe_size =  4; # number of decks to load into shoe
my @shoe      = (); # dealer's shoe holding multiple full decks shuffled
my $hand_size =  2; # number of cards to deal to each player
my @hands     = (); # player hand card  data
my $deal_min  = 17; # threshold dealer  will hit when below
my $play_min  = 11; # threshold players will hit when below
my @scores    = (); # player hand score data && purse bank-roll data below
my @purses    = (1000.0);for(my $pn=($players-1);$pn>=0;$pn--) { if($pn) {
    $purses[$pn]=  10.0 ;print 'Play';}else{print 'Deal';} # add funding
  printf("er$pn Purse:\$%7.2f\n",$purses[$pn]);} say '';
for my $round (0..($rounds-1)) { # detect -h in $rounds to just print Help
  while($players--) {
    if(scalar(@shoe) <= ($players       * ($hand_size + 5)) &&
       scalar(@shoe) <  (scalar(Deck()) *  $shoe_size     )) {
    push(@shoe, Deck())  for(1..$shoe_size); Shuffle(\@shoe);} # fill shoe
    push(    @{$hands[$players]},   pop(@shoe))  for(1..$hand_size);
              $scores[$players] = BJHandScore(@{$hands[$players]});
    if(               $players) { print 'Play';
      while(  $scores[$players] < $play_min) { # Players hit?
        push(@{$hands[$players]}, pop(@shoe));
              $scores[$players] = BJHandScore(@{$hands[$players]}); } }
    else                        { print 'Deal';
      while(  $scores[      0 ] < $deal_min) { # Dealer hits normally < 17?
        push(@{$hands[      0 ]}, pop(@shoe));
              $scores[      0 ] = BJHandScore(@{$hands[      0 ]}); } }
    printf(    "er$players Score:%4d hand:@{$hands[$players]}",
                                           $scores[$players]);     # color?
    print  ' Busted!'               if(    $scores[$players] >21); # align?
    print  ' BlackJack!'            if(BJ(@{$hands[$players]})  );say '';
  }       $players = scalar(@scores); # reload player count from score list
  while(--$players) { my $amount        = 0.0 ;
    $amount = (BJ(@{$hands[$players]})) ? 1.5 :
               BJCmp($scores[0], $scores[$players]); # CoMPare each to Dealer
    printf("Player$players cmp2D: %7.2f\n", $amount); $purses[0] -= $amount;
                                               $purses[$players] += $amount;
  } $players= scalar(@scores);@hands=(); } say ''; # reset data @ end of round
for(my $pn=($players-1);$pn>=0;$pn--) {print(($pn) ? 'Play' : 'Deal');
  printf("er$pn Purse:\$%7.2f\n", $purses[$pn]); } # show end-game purses
