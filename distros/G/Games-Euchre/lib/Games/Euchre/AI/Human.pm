# Human computer player.

# This module is licensed under the same terms as the other modules in
# this package: GPLv2

package Games::Euchre::AI::Human;

use strict;
use warnings;
use Games::Euchre::AI;

our @ISA = qw(Games::Euchre::AI);

# Words for the players
our %who = (
            0 => "you",
            1 => "your left opponent",
            2 => "your partner",
            3 => "your right opponent",
            );

# Helper function
sub who {
   my $state = shift;
   my $theirNum = shift;
   my $index = $theirNum - $state->{number} % 4;
   return $state->{names}->{$theirNum} . " ($who{$index})";
}

sub bid {
   my $self = shift;
   my $state = shift;

   my $round = ($state->{passes} < 4 ? 1 : 2);
   my $options;
   if ($round == 1) {
      my $dealer = ($state->{number} - $state->{passes} - 2) % 4 + 1;
      $self->{turnedUp} = $state->{turnedUp};
      $self->{turnedUp} =~ /(.)$/;
      my $suit = $1;
      # bid can only be turned-up suit of pass
      $options = "$suit,${suit}A,P";
      print "Dealer: " . &who($state, $dealer) . 
          " turned up: $$state{turnedUp}\n";
      # Show other players' passes
      for (my $i=0; $i < $state->{passes} % 4; $i++) {
         my $player = ($state->{number} - $state->{passes} + $i - 1) % 4 + 1;
         print &who($state, $player) . " passed\n";
      }
   } else {
      $self->{turnedUp} =~ /(.)$/;
      my $suit = $1;
      $options = "H,D,S,C,N,HA,DA,SA,CA,NA,P";
      # disallow the round 1 suit
      $options =~ s/$suit A?,//gx;
      # maybe disallow notrump
      $options =~ s/NA?,//g if (!$state->{notrump});
      # disallow pass in hand-dealer situation
      $options =~ s/,P// if ($state->{hangdealer} && $state->{passes} == 7);
      # Show other players' passes
      for (my $i=1; $i <= 3; $i++) {
         my $player = ($state->{number} + $i - 1) % 4 + 1;
         print &who($state, $player) . " passed\n";
      }
   }
   print "Your hand: " . join(" ", @{$state->{hand}}) . "\n";

   # Loop until we get a legal bid
   my $bid = "XXX";
   my $legal = 0;
   do {
      print "\nYour bid ($options): ";
      $bid = uc(<STDIN>);
      print "\n";
      # Clean up: no whitespace, pass is undef
      $bid =~ s/\s//gs;
      $bid = undef if ($bid eq "P");
      $legal = $self->isLegalBid($state, $bid);
      if (!$legal) {
         print " *** Illegal bid ***\n";
      }
   } while (!$legal);

   return $bid;
}

sub pickItUp {
   my $self = shift;
   my $state = shift;

   print "Turned up: $$state{turnedUp}\n";
   print "Your hand: " . join(" ", @{$state->{hand}}) . "\n";

   # Loop until we get a legal card
   my $index = -1;
   my $legal = 0;
   do {
      print "\nWhich card do you want to discard (1-5): ";
      $index = <STDIN>;
      print "\n";
      chomp $index;
      $legal = $index =~ /^\d$/ && $index >= 1 && $index <= 5;
      if (!$legal) {
         print " *** Not a valid card number ***\n";
      }
   } while (!$legal);

   return $index-1;
}

sub playCard {
   my $self = shift;
   my $state = shift;

   if (@{$state->{played}}) {
      for (my $i=0; $i < @{$state->{played}}; $i++) {
         print &who($state, $state->{playedBy}->[$i]) . " played " . $state->{played}->[$i] . "\n";
      }
      #print "\n";
   } else {
      print "Your lead\n";
   }
   print "Your hand: " . join(" ", @{$state->{hand}}) . ", trump: $$state{trump}, tricks: $$state{ourTricks} for us, $$state{theirTricks} for them\n";

   # Loop until we get a legal card
   my $index = -1;
   my $legal = 0;
   do {
      print "\nWhich card do you want to play (1-" . @{$state->{hand}} . "): ";
      $index = <STDIN>;
      print "\n";
      chomp $index;
      $legal = $index =~ /^\d$/ && $index >= 1 && $index <= @{$state->{hand}};
      if (!$legal) {
         print " *** Not a valid card number ***\n";
      } else {
         $legal = $self->isLegalPlay($state, $index-1);
         if (!$legal) {
            print " *** Not a legal choice ***\n";
         }
      }
   } while (!$legal);

   return $index-1;
}


sub endOfBidding {
   my $self = shift;
   my $state = shift;

   my %results = (
                  C => "CLUBS are trump",
                  H => "HEARTS are trump",
                  S => "SPADES are trump",
                  D => "DIAMONDS are trump",
                  N => "NO-TRUMP was called",
                  );

   # Say who passed before the bid
   my $bidder = $state->{bidder};
   # If all passed, pretend player after dealer was bidder
   $bidder ||= ($state->{dealer} % 4) + 1;
   my $passesPlusOne = ($bidder - $state->{number}) %4;
   for (my $i=1; $i < $passesPlusOne; $i++) {
      my $player = ($state->{number} + $i - 1) % 4 + 1;
      print &who($state, $player) . " passed\n";
   }

   if ($state->{trump}) {
      my $trumpMsg = $results{$state->{trump}};
      my $alone = $state->{usAlone} || $state->{themAlone} ? " alone" : "";
      print &who($state, $state->{bidder}) . " bid$alone, $trumpMsg\n";
   } else {
      $self->{allPassed} = 1;
      print "Bidding is over, everyone passed\n\n";
   }
}

sub endOfTrick {
   my $self = shift;
   my $state = shift;

   for (my $i=$state->{myCard}; $i<@{$state->{played}}; $i++) {
         print &who($state, $state->{playedBy}->[$i]) . " played " . $state->{played}->[$i] . "\n";      
   }

   print &who($state, $state->{winner}) . " won the trick\n\n";
}

sub endOfHand {
   my $self = shift;
   my $state = shift;


   if (!$self->{allPassed}) {
      my $who = $state->{ourTricks} > $state->{theirTricks} ? "You" : "They";
      my @tricks = sort ($state->{ourTricks}, $state->{theirTricks});
      my %score = (
                   'win' => "1",
                   'all' => "2 (all of them)",
                   'alone' => "4 (alone!)",
                   'euchre' => "2 (Euchre!)",
                   );
      print "$who won the hand $tricks[1] to $tricks[0] for a score of $score{$state->{winType}}\n";
   }
   delete $self->{turnedUp};
   delete $self->{allPassed};
}

sub endOfGame {
   my $self = shift;
   my $state = shift;

   my $who = $state->{ourScore} > $state->{theirScore} ? "You" : "They";
   my @score = sort ($state->{ourScore}, $state->{theirScore});
   print "$who won the game $score[1] to $score[0]\n";
}

1;
