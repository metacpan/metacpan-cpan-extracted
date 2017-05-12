package Games::Euchre::Player;

=head1 NAME

Games::Euchre::Player - Player class for Euchre card game

=head1 DESCRIPTION

The four Player objects are used to interact with the humand and
computer players, as well as to keep the state of the players hand,
whether he bid and whether he went alone.

=cut

require 5.005_57;
use strict;
use warnings;
use Scalar::Util;
use Games::Cards;

=head1 CLASS METHODS

=over 4

=item new GAME NUMBER NAME

Create and initialize a new Euchre player.  The number is 1-4.

=cut

sub new {
   my $pkg = shift;
   my $game = shift;
   my $number = shift; # 1-based
   my $name = shift;
   my $self =  bless({
      game => $game,
      number => $number,
      name => $name,
      hand => undef,
      team => undef,
      ai => undef,
      alone => undef,
      bid => undef,
   }, $pkg);
   return $self;
}

=back

=head1 INSTANCE METHODS

=over 4

=item getGame

Return the Euchre game instance to which this player belongs.

=cut

sub getGame {
   my $self = shift;
   return $self->{game};
}

=item setTeam TEAM

Record the Team instance that this player belongs to.

=cut

sub setTeam {
   my $self = shift;
   my $team = shift;
   $self->{team} = $team;
   weaken($self->{team}); # break anti-GC loop
   return $self;
}

=item getTeam

Return the Team instance to which this player belongs.

=cut

sub getTeam {
   my $self = shift;
   return $self->{team};
}

=item setAI AI

Record the AI instance for this player.

=cut

sub setAI {
   my $self = shift;
   my $ai = shift;
   $self->{ai} = $ai;
   return $self;
}

=item getAI

Return the AI instance for this player.

=cut

sub getAI {
   my $self = shift;
   return $self->{ai};
}

=item setAlone

Indicate that this player has chosen to go alone in the current hand.

=cut

sub setAlone {
   my $self = shift;
   $self->{alone} = 1;
   return $self;
}

=item setBid

Indicate that this player has chosen to choose trump in the current hand.

=cut

sub setBid {
   my $self = shift;
   $self->{bid} = 1;
   return $self;
}

=item wentAlone

Returns a boolean indicating whether this player chose to go alone on
a bid.

=cut

sub wentAlone {
   my $self = shift;
   return $self->{alone};
}

=item isBidder

Returns a boolean indicating whether this player called the trump suit
during bidding.

=cut

sub isBidder {
   my $self = shift;
   return $self->{bid};
}

=item getName

Return this player's name

=cut

sub getName {
   my $self = shift;
   return $self->{name};
}

=item getNumber

Return this player's number, between 1 and 4

=cut

sub getNumber {
   my $self = shift;
   return $self->{number};
}

=item getHand

Return the Games::Cards::Hand object representing this player's
current hand.

=cut

sub getHand {
   my $self = shift;
   return $self->{hand};
}

=item getCards

Return an array of the Games::Cards::Card objects held in the player's hand.

=cut

sub getCards {
   my $self = shift;
   return @{$self->getHand()->cards()};
}

=item resetGame

Clear all of the state for the current game and get ready for the next one.

=cut

sub resetGame {
   my $self = shift;
   return $self->resetHand();
}

=item resetHand

Clear all of the state for the current hand and get ready for the next one.

=cut

sub resetHand {
   my $self = shift;
   $self->{alone} = undef;
   $self->{bid} = undef;
   $self->{hand} = Games::Cards::Hand->new($self->getGame()->{game}, $self->{name});
   return $self;
}

=item bid TURN

Allow the player to choose trump or pass.  Returns one of: H, C, D, S,
N, HA, CA, DA, SA, NA, or undef.  If the player has an AI instance
set, that is invoked.  Otherwise a pathetically simple AI decides the
bid.

=cut

sub bid {
   my $self = shift;
   my $turn = shift;

   if ($self->getAI()) {
      my $state = {
         name        => $self->getName(),
         names       => {$self->getGame()->getPlayerNames()},
         number      => $self->getNumber(),
         turnedUp    => ($turn <= 4 ?
                         $self->getGame()->{blind}->top_card()->truename() :
                         undef),
         passes      => $turn-1,
         ourScore    => $self->getTeam()->getScore(),
         theirScore  => $self->getTeam()->getOtherTeam()->getScore(),
         winScore    => $self->getGame()->{winningScore},
         hangdealer  => $self->getGame()->{hangdealer},
         notrump     => $self->getGame()->{notrump},
         trump       => $self->getGame()->{trump},
         hand        => [map {$_->truename()} $self->getCards()],
         debug       => $self->getGame()->{debug},
      };
      my $suit = $self->getAI()->bid($state);
      if ($self->isLegalBid($turn, $suit)) {
         return $suit;
      }
   } else {
      # DUMB computer player!!! pass unless last bid, then pick any one
      if ($turn == 2*$self->getGame()->getPlayers()) {
         # pick any card in hand
         foreach my $card ($self->getCards()) {
            my $suit = $self->getGame()->getCardSuit($card);
            if ($self->isLegalBid($turn, $suit)) {
               return $suit;
            }
         }
         # pick any suit
         foreach my $suit ("H", "S", "D", "C") {
            if ($self->isLegalBid($turn, $suit)) {
               return $suit;
            }
         }            
      } else {
         return undef;
      }
   }
   die "Failed to get a legal bid";
}

=item pickItUp

Allow the player, as dealer, to select which card to trade for the
turned up card.  This method performs the actual trade.  If the player
has an AI instance set, that is invoked.  Otherwise a pathetically
simple AI chooses the card.

=cut

sub pickItUp {
   my $self = shift;

   my @cards = $self->getCards();
   my $index = undef;
   if ($self->getAI()) {
      my $state = {
         name        => $self->getName(),
         names       => {$self->getGame()->getPlayerNames()},
         number      => $self->getNumber(),
         turnedUp    => $self->getGame()->{blind}->top_card()->truename(),
         trump       => $self->getGame()->{trump},
         bidder      => $self->getGame()->{bidder}+1,
         weBid       => $self->getTeam()->isBidder(),
         usAlone     => $self->getTeam()->wentAlone(),
         themAlone   => $self->getTeam()->getOtherTeam()->wentAlone(),
         hand        => [map {$_->truename()} @cards],
         debug       => $self->getGame()->{debug},
      };
      $index = $self->getAI()->pickItUp($state);
   } else {
      # DUMB computer player!!! pick the first card
      $index = 0;
   }
   if (defined $index && $index =~ /^\d+$/ && 
       $index >= 0 && $index < @cards) {
      print($self->getName() . " trades " . $cards[$index]->truename() . " for " . 
            $self->getGame()->{blind}->top_card()->truename() . "\n")
          if ($self->getGame()->{debug});
      $self->getGame()->{blind}->give_cards($self->getHand(), 1);
      $self->getHand()->give_a_card($self->getGame()->{blind}, $index);
   } else {
      die "Failed to specify a legal card to discard";
   }
}

=item playCard TRICK

Allow the player to select which card to play on the current trick.
This method performs the actual play.  If the player has an AI
instance set, that is invoked.  Otherwise a pathetically simple AI
chooses the card.

=cut

sub playCard {
   my $self = shift;
   my $trick = shift;

   my @cards = $self->getCards();
   my $playedCard = undef;
   if ($self->getAI()) {
      my $state = {
         name        => $self->getName(),
         names       => {$self->getGame()->getPlayerNames()},
         number      => $self->getNumber(),
         trump       => $self->getGame()->{trump},
         trick       => $trick->getNumber(),
         bidder      => $self->getGame()->{bidder}+1,
         weBid       => $self->getTeam()->isBidder(),
         usAlone     => $self->getTeam()->wentAlone(),
         themAlone   => $self->getTeam()->getOtherTeam()->wentAlone(),
         ourTricks   => $self->getTeam()->getTricks(),
         theirTricks => $self->getTeam()->getOtherTeam()->getTricks(),
         ourScore    => $self->getTeam()->getScore(),
         theirScore  => $self->getTeam()->getOtherTeam()->getScore(),
         winScore    => $self->getGame()->{winningScore},
         played      => [map {$_->truename()} $trick->getCards()],
         playedBy    => [map {$_->getNumber()} $trick->getPlayers()],
         hand        => [map {$_->truename()} @cards],
         debug       => $self->getGame()->{debug},
      };
      my $index = $self->getAI()->playCard($state);
      if ($trick->isLegalPlay($self, $index)) {
         $playedCard = $cards[$index];
         $self->getHand()->give_a_card($trick->getHand(), $index);
      }      
   } else {
      # DUMB computer player!!! pick the first legal card
      for (my $i=0; $i < @cards; $i++) {
         if ($trick->isLegalPlay($self, $i)) {
            $playedCard = $cards[$i];
            print($self->getName() . " plays " . $playedCard->truename() . 
                  " on " . $self->getHand()->print("short"))
                if ($self->getGame()->{debug});
            $self->getHand()->give_a_card($trick->getHand(), $i);
            last;
         }
      }
   }
   if (!$playedCard) {
      die "Failed to find a legal card to play";
   }
}

=item isLegalBid TURNNUMBER BID

Given a bid, return a boolean indicating the validity of that bid.
The bid is tested for structure (one of H, C, D, S, N, HA, CA, DA, SA,
NA, or undef), tested against the bidding round (only the turned-up
card suit can be called in round 1 , and may not be called in round
2), against the game options (hang-the-dealer, no-trump).

This is called from the bid() method.

=cut

sub isLegalBid {
   my $self = shift;
   my $turn = shift;
   my $bid = shift;
   
   my $game = $self->getGame();

   my @players = $game->getPlayers();
   my $lastturn = 2*@players;

   # Is it a pass?
   if (!defined $bid) {
      # Can't pass on the last bid if hang-the-dealer is in effect
      if ($game->{hangdealer} && $turn == $lastturn) {
         return undef;
      } else {
         return $self;
      }
   }

   # Is is a valid bid?
   return undef if ($bid !~ /^([HSDCN])(|A)$/i);

   my $suit = uc($1);
   my $alone = $2;

   # Is it no trump?
   if ($suit eq "N") {
      # NT must be enable to call it
      return undef if (!$game->{notrump});
   }

   # Must call THE suit in the first round
   if ($turn <= @players) {
      my $topsuit = $game->getCardSuit($game->{blind}->top_card());
      return undef if ($suit ne $topsuit);
   }

   return $self;
}

1;
__END__

=back

=head1 SEE ALSO

Games::Euchre

=head1 LICENSE

GNU Public License, version 2

=head1 AUTHOR

Chris Dolan, I<chrisdolan@users.sourceforge.net>

=cut
