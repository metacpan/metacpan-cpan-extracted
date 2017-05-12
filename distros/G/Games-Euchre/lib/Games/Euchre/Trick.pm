package Games::Euchre::Trick;

=head1 NAME

Games::Euchre::Trick - Trick class for Euchre card game

=head1 DESCRIPTION

Only one Trick instance is alive at one time per Euchre game.  The
Trick keeps track of which cards have been played, and provides useful
functions to determine which cards are legal plays, as well as who
is the winner of the trick.  The trick class makes the determination
of which card beats which card, given the current trump and lead.  The
trick class knows how to handle an alone hand and it calls the
playCard() method for each player in turn in it's play() method,
usually called from the Games::Euchre->playHand() method.

=cut

use strict;
use warnings;
use Games::Cards;

=head1 CLASS METHODS

=over 4

=item new GAME LEAD NAME NUMBER

Create and initialize a new Euchre trick.  The lead is a
Games::Euchre::Player instance.  The name is any string.  The number
is a one-based index of which trick this is (from 1 to 5).

=cut

sub new {
   my $pkg = shift;
   my $game = shift;
   my $lead = shift;
   my $name = shift;
   my $number = shift;  # 1-based
   my $self =  bless({
      game => $game,
      name => $name,
      number => $number,
      players => [$game->getPlayers()],
      hand => Games::Cards::Queue->new($game->{game}, $name),
      play => 0,
      leadIndex => undef,
   }, $pkg);
   for (my $i=$#{$self->{players}}; $i >= 0; $i--) {
      my $player = $self->{players}->[$i];
      if ((!$player->wentAlone()) && $player->getTeam()->wentAlone()) {
         # Remove teammate of alone-goer
         splice @{$self->{players}}, $i, 1;
      }
   }

   for (my $i=0; $i < @{$self->{players}}; $i++) {
      last if ($lead->getName() eq $self->{players}->[0]->getName());
      push @{$self->{players}}, shift(@{$self->{players}}); # rotate
   }
   return $self;
}

=back

=head1 CLASS METHODS

=over 4

=item getGame

Return the Euchre game instance to which this trick belongs.

=cut

sub getGame {
   my $self = shift;
   return $self->{game};
}

=item getName

Return the name of this trick.

=cut

sub getName {
   my $self = shift;
   return $self->{name};
}

=item getNumber

Return the number of this trick (from 1 to 5).

=cut

sub getNumber {
   my $self = shift;
   return $self->{number};
}

=item getHand

Return the Games::Cards::Hand object representing this trick.

=cut

sub getHand {
   my $self = shift;
   return $self->{hand};
}

=item getCards

Return an array of the Games::Cards::Card objects played in this trick.

=cut

sub getCards {
   my $self = shift;
   return @{$self->getHand()->cards()};
}

=item getPlayers

Return an array of the players in the order they will play in this
trick.  If someone went alone, this array will have three entries.
Otherwise it will always have four.

=cut

sub getPlayers {
   my $self = shift;
   return @{$self->{players}};
}

=item getPlayerIndex PLAYER

Returns the 0-based index of the specified player in the order that he
would play in the current trick.  This is crucial for figuring out who
played which card.  Returns undef in the case that the player did not
play (yet, or not at all if the partner went alone).

=cut

sub getPlayerIndex {
   my $self = shift;
   my $player = shift;
   for (my $i=0; $i < @{$self->{players}}; $i++) {
      if ($player->getName() eq $self->{players}->[$i]->getName()) {
         return $i;
      }
   }
   return undef;
}

=item recordTrick

Record the result of this trick by informing the winning team.

=cut

sub recordTrick {
   my $self = shift;
   my $winner = $self->getWinner();
   $winner->getTeam()->addTrick();
}

=item getWinner

Returns the player who played the card that won the trick.

=cut

sub getWinner {
   my $self = shift;
   
   my @cards = $self->getCards();
   my $leader = 0;
   for (my $i=1; $i<@cards; $i++) {
      if ($self->cmpCards($cards[$leader], $cards[$i]) < 0) {
         $leader = $i;
      }
   }
   #print "winner: " . $self->{players}->[$leader]->getName() . "\n"
   #    if ($self->getGame()->{debug});
   return $self->{players}->[$leader];
}

=item cmpCards CARD1 CARD2

Returns -1, 0, or 1 indicating the relative rank of the two cards.
Like the string 'cmp' operator -1 means that CARD2 beats CARD1, 1
means that CARD1 beats CARD2 and 0 means that they are equivalent
(i.e. both worthless!).

=cut

sub cmpCards {
   my $self = shift;
   my @cards = (shift, shift);

   my $leadcard = ($self->getCards())[0];
   my $leadsuit = $self->getGame()->getCardSuit($leadcard);
   my $trumpsuit = $self->getGame()->{trump};
   my $othertrumpsuit = $self->getGame()->{othertrump};
   # This is valid for NT too, since the "JN" for trump is never referenced
   my %ranks = (
                "A$leadsuit"  => 6,
                "K$leadsuit"  => 5,
                "Q$leadsuit"  => 4,
                "J$leadsuit"  => 3,
                "10$leadsuit" => 2,
                "9$leadsuit"  => 1,

                # Order matters:
                # trump has to be after lead in case lead IS trump
                # or if lead suit holds left jack
                "J$trumpsuit"  => 13,
                "J$othertrumpsuit"  => 12,
                "A$trumpsuit"  => 11,
                "K$trumpsuit"  => 10,
                "Q$trumpsuit"  => 9,
                "10$trumpsuit" => 8,
                "9$trumpsuit"  => 7,
                );

   my @cardranks = map {$ranks{$_->truename()} || 0} @cards;
   #print "cmp " . join(" vs. ", map{$cards[$_]->truename()." $cardranks[$_]"} 0,1) . "\n"
   #    if ($self->getGame()->{debug});
   return $cardranks[0] <=> $cardranks[1];
}

=item play

Calls the playCard() method for the player whose turn it is to play.

=cut

sub play {
   my $self = shift;
   my $player = $self->{players}->[$self->{play}++];
   $player->playCard($self);
   return $self;
}

=item isLegalPlay PLAYER CHOICE

Returns a boolean indicating whether the selected card to play is
legal, given the specified player's hand.  CHOICE is a 0-based index
into the array of cards held by the player's hand.

Checks if the choice is an actual card in the player's hand and
whether the card follows suit.

=cut

sub isLegalPlay {
   my $self = shift;
   my $player = shift;
   my $choice = shift; # 0-based

   my @cards = $player->getCards();

   # Enforce valid choice values
   return undef unless (defined $choice && $choice =~ /^\d$/ &&
                        $choice >= 0 && $choice < @cards);
   my $card = $cards[$choice];
   return undef if (!$card);

   # Is it the first card led?
   my $leadcard = ($self->getCards())[0];
   return $self if (!$leadcard);  # lead card can be anything

   # Is it following suit?
   my $cardsuit = $self->getGame()->getCardSuit($card);
   my $leadsuit = $self->getGame()->getCardSuit($leadcard);
   return $self if ($cardsuit eq $leadsuit);

   # Is the player out of the lead suit?
   my $hasLeadSuit = undef;
   foreach my $card (@cards) {
      my $cardsuit = $self->getGame()->getCardSuit($card);
      if ($cardsuit eq $leadsuit) {
         $hasLeadSuit = $self;
         last;
      }
   }
   return !$hasLeadSuit;
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
