package Games::Euchre;

=head1 NAME

Games::Euchre - Euchre card game for humans and computers

=head1 SYNOPSIS

Simply run my game wrapper:

  % euchre.pl

or write your own:

  use Games::Euchre;
  use Games::Euchre::AI::Simple;
  use Games::Euchre::AI::Human;

  my $game = Games::Euchre->new();
  foreach my $i (1..3) {
     $game->setAI($i, Games::Euchre::AI::Simple->new());
  }
  $game->setAI(4, Games::Euchre::AI::Human->new());
  $game->playGame();
  my @scores = sort {$b <=> $a} $game->getScores();
  print("The winner is " . $game->getWinner()->getName() . " with a score of " .
        "$scores[0] to $scores[1]\n");

=head1 DESCRIPTION

This software implements the card game of Euchre.  The game is played
with four players composing two teams.  Any of the four players can be
human or computer players, but more than one human is not well
supported yet.

The Games::Euchre::AI module implements a simple framework for adding
new classes of human interfaces or computer opponents.  I recomment
that AI writers use Games::Euchre::AI::Simple (a REALLY dumb computer
opponent) as starting point.

Aside from the ::AI class and its descendents, this package also
implements the following classes: Games::Euchre::Team,
Games::Euchre::Player and Games::Euchre::Trick.

=cut

require 5.005_62;
use strict;
use warnings;
use Games::Cards;
use Games::Euchre::Team;
use Games::Euchre::Player;
use Games::Euchre::Trick;

our $VERSION = '1.02';

=head1 CLASS METHODS

=over 4

=item new

Create and initialize a new Euchre game.

=cut

sub new {
   my $pkg = shift;

   my %values = (
                 9 => 9,
                 10 => 10,
                 "J" => 11,
                 "Q" => 12,
                 "K" => 13,
                 "A" => 14,
                 );
   
   my $self = bless({
      game => Games::Cards::Game->new({cards_in_suit => \%values}),
      notrump => undef,
      hangdealer => undef,
      winningScore => 10,
      trump => undef,
      deck => undef,
      blind => undef,
      dealer => undef,
      bidder => undef,
      players => [],
      teams => [],
   }, $pkg);
   $self->resetGame();
   return $self;
}

=back

=head1 INSTANCE METHODS

=head2 Pre-Game methods

=over 4

=cut

=item enableHangDealer

Turns on the hang-the-dealer game option.  It is off by default.  If
on, this means that the dealer may not pass in the second bidding
round.  Otherwise, the deal passes to the next player and bidding
begins anew.

=cut

sub enableHangDealer {
   my $self = shift;
   $self->{hangdealer} = 1;
   return $self;
}

=item enableNoTrump

Turns on the no-trump game option.  It is off by default.  If on, this
means that in the second round of bidding, players may declare "No
trump".

=cut

sub enableNoTrump {
   my $self = shift;
   $self->{notrump} = 1;
   return $self;
}

=item setAI INDEX AI_OBJECT

Tells the game to use the specified AI instance to control the player
of the given index.  The index must be an integer between 1 and 4.
The AI instance must inherit from Games::Euchre::AI.

=cut

sub setAI {
   my $self = shift;
   my $index = shift; # one-based
   my $ai = shift;
   die "Bad index" unless ($index && $index =~ /^[1-4]$/);
   die "Invalid AI instance" unless ($ai && ref($ai) &&
                                     $ai->isa("Games::Euchre::AI"));
   $self->{players}->[$index-1]->setAI($ai);
   return $self;
}

=back

=head2 Game Methods

=over 4

=item resetGame

Clear all of the state for the current game and get ready for the next one.

=cut

sub resetGame {
   my $self = shift;

   $self->{dealer} = 0;
   $self->{players} ||= [];
   $self->{teams} ||= [];

   foreach my $i (1 .. 4) {
      $self->{players}->[$i-1] 
          ||= Games::Euchre::Player->new($self, $i, "Player $i");

      # Refresh the old AI, if any
      my $player = $self->{players}->[$i-1];
      my $ai = $player->getAI();
      if ($ai) {
         if ($ai->persist()) {
            $ai->reset();
         } else {
            my $pkg = ref($ai);
            $player->setAI($pkg->new());
         }
      }
   }

   foreach my $i (1 .. 2) {
      if (!$self->{teams}->[$i-1]) {
         my $team = Games::Euchre::Team->new($self, $i, "Team $i",
                                             $self->{players}->[$i-1],
                                             $self->{players}->[$i+1]);
         foreach my $player ($team->getPlayers()) {
            $player->setTeam($team);
         }
         $self->{teams}->[$i-1] = $team;
      }
   }

   foreach my $player ($self->getPlayers()) {
      $player->resetGame();
   }
   foreach my $team ($self->getTeams()) {
      $team->resetGame();
   }
   return $self->resetHand();
}

=item resetHand

Clear all of the state for the current hand and get ready for the next one.

=cut

sub resetHand {
   my $self = shift;

   $self->{bidder} = undef;
   $self->{trump} = undef;
   $self->{othertrump} = undef;
   $self->{deck} = Games::Cards::Deck->new($self->{game}, "Deck");
   $self->{deck}->shuffle();
   $self->{blind} = Games::Cards::Stack->new($self->{game}, "blind");
   $self->{deck}->give_cards($self->{blind}, 4);

   foreach my $team ($self->getTeams()) {
      $team->resetHand();
   }
   foreach my $player ($self->getPlayers()) {
      $player->resetHand();
      $self->{deck}->give_cards($player->getHand(), 5);
      $player->getHand()->sort_by_value();
   }
}

=item playGame

Start a game.

=cut

sub playGame {
   my $self = shift;
   $self->resetGame();
   while (!$self->getWinner()) {
      $self->playHand();
      # Announce the end of the hand to AI players
      $self->announceEndOfHand()
   }
   # Announce the end of the game to AI players
   $self->announceEndOfGame();
}

=item playHand

Start a hand.  Called from playGame().

=cut

sub playHand {
   my $self = shift;
   $self->resetHand();
   if (!$self->getBid()) {
      $self->announceEndOfBidding();
      $self->nextDealer();
      return $self;
   }
   $self->announceEndOfBidding();
   my $lead = ($self->getPlayers())[$self->{dealer} + 1 % 4];
   foreach my $trickNum (1 .. 5) {
      my $trick = $self->getNewTrick($lead, $trickNum);
      for (1 .. $self->getPlayers()) {
         $trick->play();
      }
      $trick->recordTrick();
      my $winner = $trick->getWinner();
      $self->announceEndOfTrick($trick);
      $lead = $winner;
   }
   $self->scoreHand();

   $self->nextDealer();
   return $self;
}

=item getBid

Called from playHand().

=cut

sub getBid {
   my $self = shift;
   
   #print "Blind shows " . $self->{blind}->top_card()->truename() . "\n" 
   #    if ($self->{debug});
   my @players = $self->getPlayers();
   my $lastbid = 2*@players;
   for (my $turn = 1; $turn <= $lastbid; $turn++) {
      my $index = ($self->{dealer} + $turn) % @players;
      my $trump = $players[$index]->bid($turn);
      if (defined $trump) {
         $self->{bidder} = $index;
         $players[$index]->setBid();
         if ($trump =~ s/A//) {
            $players[$index]->setAlone();
         }
         $self->setTrump($trump);
         if ($turn <= @players) {
            # First round, dealer trades for turned card
            $players[$self->{dealer}]->pickItUp();
         }
         #print($players[$index]->getName() . " called $trump for trump" .
         #      ($players[$index]->wentAlone() ? ", alone" : "") . "\n")
         #    if ($self->{debug});
         last;
      }
   }
   if (!defined $self->{trump}) {
      return undef;  # signal that all players passed
   }
   return $self;
}

=item nextDealer

Called from playHand().

=cut

sub nextDealer {
   my $self = shift;
   $self->{dealer}++;
   $self->{dealer} %= $self->getPlayers();
   return $self;
}

=item setTrump TRUMPSUIT

Records the trump suit for this hand.  Also computes the suit of the
left jack for convenience.  No-trump is handled correctly.  Called
from getBid().

=cut

sub setTrump {
   my $self = shift;
   my $trump = shift;
   $self->{trump} = $trump;
   my %othertrump = (
                     D => "H",
                     C => "S",
                     H => "D",
                     S => "C",
                     N => "",
                     );
   $self->{othertrump} = $othertrump{$trump};
   return $self;
}

=item getNewTrick LEADPLAYER TURNNUMBER

Instantiate and return a new Games::Euchre::Trick object.  Called from playHand().

=cut

sub getNewTrick {
   my $self = shift;
   my $lead = shift;
   my $number = shift;  # 1-based
   return Games::Euchre::Trick->new($self, $lead, "Trick $number", $number);
}

=item scoreHand

At the end of a hand, update the scores for the teams.

=cut

sub scoreHand {
   my $self = shift;
   my @scores = $self->computeHandScores();
   foreach my $team ($self->getTeams()) {
      $team->addScore(shift @scores);
   }
   return $self;
}

=item computeHandScores

At the end of a hand, compute how many points each team deserves to
gain for the tricks they won.  Returns an array of these score
increments.  This method does not record any changes at all.  Called
by scoreHand().

=cut

sub computeHandScores {
   my $self = shift;

   my %scoreMap = ('win' => 1, 'euchre' => 2,
                   'all' => 2, 'alone' => 4);
   return map {$scoreMap{$_} || 0} $self->computeWinTypes();
}

=item computeWinTypes

At the end of a hand, compute what type of result each team deserves
to gain for the tricks they won: one of 'win', 'all', 'alone', or
'euchre'.  Returns an array of these win types increments.  This
method does not record any changes at all.  Called by
computeHandScores().

=cut

sub computeWinTypes {
   my $self = shift;

   my @winTypes = ();
   foreach my $team ($self->getTeams()) {
      my $tricks = $team->getTricks();
      my $win = "";
      if ($tricks >= 3) {
         $win = "win";
         if (!$team->isBidder()) {
            $win = "euchre";
         } elsif ($tricks >= 5) {
            $win = "all";
            if ($team->wentAlone()) {
               $win = "alone";
            }
         }
      }
      push @winTypes, $win;
   }
   return @winTypes;
}

=item announceEndOfBidding

Tell AIs the results of the bidding.

=cut

sub announceEndOfBidding {
   my $self = shift;
   
   foreach my $player ($self->getPlayers()) {
      if ($player->getAI()) {
         my $state = {
            name        => $player->getName(),
            names       => {$self->getPlayerNames()},
            number      => $player->getNumber(),
            trump       => $self->{trump},
            dealer      => $self->{dealer},
            bidder      => defined $self->{bidder} ? $self->{bidder}+1 : undef,
            weBid       => $player->getTeam()->isBidder(),
            usAlone     => $player->getTeam()->wentAlone(),
            themAlone   => $player->getTeam()->getOtherTeam()->wentAlone(),
            debug       => $self->{debug},
         };
         $player->getAI()->endOfBidding($state);
      }
   }
}

=item announceEndOfTrick TRICK

Tell AIs the results of the trick.

=cut

sub announceEndOfTrick {
   my $self = shift;
   my $trick = shift;

   my $winner = $trick->getWinner();
   my $winCard = $trick->getPlayerIndex($winner);
   foreach my $player ($self->getPlayers()) {
      if ($player->getAI()) {
         my $state = {
            name        => $player->getName(),
            names       => {$self->getPlayerNames()},
            number      => $player->getNumber(),
            played      => [map {$_->truename()} $trick->getCards()],
            playedBy    => [map {$_->getNumber()} $trick->getPlayers()],
            myCard      => $trick->getPlayerIndex($player),
            winCard     => $winCard,
            winner      => $winner->getNumber(),
            debug       => $self->{debug},
         };
         $player->getAI()->endOfTrick($state);
      }
   }
}

=item announceEndOfHand

Tell AIs the results of the hand.

=cut

sub announceEndOfHand {
   my $self = shift;
   
   # Retrieve the wintype of the winning team
   my ($winType) = grep {$_} $self->computeWinTypes();
   foreach my $player ($self->getPlayers()) {
      if ($player->getAI()) {
         my $state = {
            name        => $player->getName(),
            names       => {$self->getPlayerNames()},
            number      => $player->getNumber(),
            ourTricks   => $player->getTeam()->getTricks(),
            theirTricks => $player->getTeam()->getOtherTeam()->getTricks(),
            winType     => $winType,
            ourScore    => $player->getTeam()->getScore(),
            theirScore  => $player->getTeam()->getOtherTeam()->getScore(),
            winScore    => $self->{winningScore},
            debug       => $self->{debug},
         };
         $player->getAI()->endOfHand($state);
      }
   }
}

=item announceEndOfGame

Tell AIs the results of the game.

=cut

sub announceEndOfGame {
   my $self = shift;

   foreach my $player ($self->getPlayers()) {
      if ($player->getAI()) {
         my $state = {
            name        => $player->getName(),
            names       => {$self->getPlayerNames()},
            number      => $player->getNumber(),
            ourScore    => $player->getTeam()->getScore(),
            theirScore  => $player->getTeam()->getOtherTeam()->getScore(),
            debug       => $self->{debug},
         };
         $player->getAI()->endOfHand($state);
      }
   }
}

=back

=head2 Utility/Access Methods

=over 4

=item getWinner

Returns the Team object who has won the game, or undef if nobody has won yet.

=cut

sub getWinner {
   my $self = shift;
   foreach my $team ($self->getTeams()) {
      return $team if ($team->getScore() >= $self->{winningScore});
   }
   return undef;
}

=item getTeams

Returns an array of two Team objects.

=cut

sub getTeams {
   my $self = shift;
   return @{$self->{teams}};
}

=item getPlayers

Returns an array of four Player objects.

=cut

sub getPlayers {
   my $self = shift;
   return @{$self->{players}};
}

=item getPlayerNames

Returns a hash relating player numbers to player names for all four
players.

=cut

sub getPlayerNames {
   my $self = shift;
   return map {$_->getNumber(), $_->getName()} $self->getPlayers();
}

=item getScores

Returns an array of current scores for the two teams.  The order of
the returned scores is the same as the order of the returned teams in
the getTeams() method.

=cut

sub getScores {
   my $self = shift;
   return map {$_->getScore()} $self->getTeams();
}

=item getCardSuit CARD

Returns the suit of the given card.  The left jack is reported to be
of the trump suit, if a trump has been declared.  [This latter
convenience is the whole point of having this function at all and not
just calling CARD->suit().]

=cut

sub getCardSuit {
   my $self = shift;
   my $card = shift;
   my $cardsuit = $card->suit();
   if ($self->{trump} && $self->{othertrump} && 
       $cardsuit eq $self->{othertrump} && $card->name() eq "J") {
      $cardsuit = $self->{trump};
   }
   return $cardsuit;
}

1;
__END__

=back

=head1 SEE ALSO

Games::Cards by Amir Karger

=head1 LICENSE

GNU Public License, version 2

=head1 AUTHOR

Chris Dolan, I<chrisdolan@users.sourceforge.net>

=cut
