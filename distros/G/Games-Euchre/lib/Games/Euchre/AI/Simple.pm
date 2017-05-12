# _DUMB_ computer player.  This is pretty much just a clone of the
# built-in computer player in Euchre.pm, but it would also make a good
# starting place for other computer players to start from.

# This module is licensed under the same terms as the other modules in
# this package: GPLv2

package Games::Euchre::AI::Simple;

use strict;
use warnings;
use Games::Euchre::AI;

our @ISA = qw(Games::Euchre::AI);

sub bid {
   my $self = shift;
   my $state = shift;

   # DUMB computer player!!! pass unless last bid, then pick any one
   if ($state->{passes} == 7) {
      # pick any card in hand
      foreach my $card (@{$state->{hand}}) {
         my $suit = $self->getCardSuit($state, $card);
         if ($self->isLegalBid($state, $suit)) {
            return $suit;
         }
      }
      # pick any suit
      foreach my $suit ("H", "S", "D", "C") {
         if ($self->isLegalBid($state, $suit)) {
            return $suit;
         }
      }            
   } else {
      return undef;
   }
}

sub pickItUp {
   my $self = shift;
   my $state = shift;

   # DUMB computer player!!! pick the first card
   return 0;
}

sub playCard {
   my $self = shift;
   my $state = shift;

   # DUMB computer player!!! pick the first legal card
   for (my $i=0; $i < @{$state->{hand}}; $i++) {
      if ($self->isLegalPlay($state, $i)) {
         print($state->{name} . " plays " . $state->{hand}->[$i] . 
               " on " . join(" ", @{$state->{hand}}) . "\n")
             if ($state->{debug});
         return $i;
      }
   }

   die "No legal play????  Impossible!";
}

1;
