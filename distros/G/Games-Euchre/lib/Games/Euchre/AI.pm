package Games::Euchre::AI;

=head1 NAME

Games::Euchre::AI - Player API for Euchre card game

=head1 DESCRIPTION

This class implements a skeletal Euchre player programming interface.
Subclasses can be created quite easily as interactive interfaces or AI
computer players.

If you wish to write your own computer player, I recommend you start
with Games::Euchre::AI::Simple.  If you wish to write your own human
interface, I recommend you start with Games::Euchre::AI::Human.

=cut

use strict;
use warnings;

=head1 CLASS METHODS

=over 4

=item new

Create and initialize a new Euchre AI.  This object is implemented as
an empty hash.  Subclasses may wish to use this hash for state
storage.

=cut

sub new {
   my $pkg = shift;
   return bless({
      # subclasses can store anything they want in here
      # because $self is unused by this superclass
   }, $pkg);
}

=back

=head1 INSTANCE METHODS

=head2 Actions

The following methods are called in the course of the game where the AI (or human) has to make a decision.  The state of the game is always passed in a hashreference.  The following fields are always available:

'name' is the name of the current player.  This is useful for output
messages.

'names' is a hash relating player number to player name for all four
players.

'debug' is a boolean indicating if we are debugging game or the AIs.
Your AI may wish to provide verbose output if debugging is going on.

=over 4

=item bid STATEHASH

Choose trump or pass.  The relevent details of the current state of
the game are provided in a hash reference.  Here is an example of that
data structure:

 {
   name        => 'Player 1',
   names       => {1 => 'Player 1', 2 => 'P2', 3 => 'P3', 4 => 'Fred'},
   number      => 1,
   turnedUp    => 'KH',
   passes      => 1,
   ourScore    => 2,
   theirScore  => 4,
   winScore    => 10,
   hangdealer  => false,
   notrump     => false,
   hand        => ['JS', 'QH', '9S', 'KC', 'AD'],
   debug       => false,
 }

'turnedUp' is the suit and value of the card on the top of the blind.
This will be undef on the second round of bidding.

'passes' says how many people have passed so far

'hangdealer' is a boolean saying whether the 'hang-the-dealer'
optional rule is in effect

'notrump' is a boolean saying whether the 'no trump' optional rule is in effect

This function must return one of: H, D, C, S, N, HA, DA, CA, SA, NA, or undef

'N' means 'no trump', 'A' means 'alone', undef means 'pass'.  Not all
of these are legal at any given round!  Use the isLegalBid() method
below if you are unsure.

=cut

sub bid {
   my $self = shift;
   my $state = shift;

   return undef; # pass (may not be legal)
}

=item pickItUp STATEHASH

If this is called, you are the dealer and someone called trump.
Choose which card from your hand to discard in exchange for the top
card of the blind.  The relevent details of the current state of the
game are provided in a hash reference.  Here is an example of that
data structure:

 {
   name        => 'Player 1',
   names       => {1 => 'Player 1', 2 => 'P2', 3 => 'P3', 4 => 'Fred'},
   number      => 1,
   turnedUp    => 'KH',
   trump       => 'H',
   bidder      => 2,
   weBid       => false,
   usAlone     => false,
   themAlone   => false,
   hand        => ['JS', 'QH', '9S', 'KC', 'AD'],
   debug       => false,
 }

This method should return the 0-based index of the card to trade for
the turnedUp card.  Namely, this in the index of the 'hand' array for
the card that you choose.

=cut

sub pickItUp {
   my $self = shift;
   my $state = shift;

   return 0; # first card
}

=item playCard STATEHASH

Choose which card from your hand to play on this trick.  The relevent
details of the current state of the game are provided in a hash
reference.  Here is an example of that data structure:

 {
   name        => 'Player 1',
   names       => {1 => 'Player 1', 2 => 'P2', 3 => 'P3', 4 => 'Fred'},
   number      => 1,
   trump       => 'H',
   bidder      => 2,
   weBid       => true,
   usAlone     => false,
   themAlone   => false,
   trick       => 2,
   ourTricks   => 0,
   theirTricks => 1,
   ourScore    => 2,
   theirScore  => 4,
   winScore    => 10,
   played      => ['10H', '9H', 'QC'],
   playedBy    => [2, 3, 4, 1],
   hand        => ['JH', 'AH', 'AS', 'KS'],
   debug       => false,
 }

'playedBy' is an arrayref of numbers of the players in the order they
will play.  Without this, the alone possibility makes it hard to tell
who played what.

Any needed information not stored here (like who was the dealer, what
was the turn-up card, what happened in the first trick) is YOUR
responsibility to collect and store in your instance.

This method should return the 0-based index of the card to play.
Namely, this in the index of the 'hand' array for the card that you
choose.

=cut

sub playCard {
   my $self = shift;
   my $state = shift;

   return 0; # first card (may not be legal)
}

=back

=head2 Event handlers

These methods are called when certain events happen in the game.  They
are for informational purposes only, and no values should be returned.
Unlike the methods above, these really only need to be overridden for
human players, or debugging output, or ubersmart robots.

=over 4

=item endOfBidding STATEHASH

 {
   name        => 'Player 1',
   names       => {1 => 'Player 1', 2 => 'P2', 3 => 'P3', 4 => 'Fred'},
   number      => 1,
   trump       => 'H',
   dealer      => 1,
   bidder      => 2,
   weBid       => false,
   usAlone     => false,
   themAlone   => false,
   debug       => false,
 }

'trump' may be undef if everybody passed (which means a new turn is
about to start).

=cut

sub endOfBidding {
   my $self = shift;
   my $state = shift;
   # do nothing
}


=item endOfTrick STATEHASH

 {
   name        => 'Player 1',
   names       => {1 => 'Player 1', 2 => 'P2', 3 => 'P3', 4 => 'Fred'},
   number      => 1,
   played      => ['KH', '9H', 'JC', '9S'],
   playedBy    => [2, 3, 4, 1],
   myCard      => 3,
   winCard     => 0,
   winner      => 2,
   debug       => false,
 }

'playedBy' is an arrayref of numbers of the players in the order they
will play.  Without this, the alone possibility makes it hard to tell
who played what.

'myCard' is 0-based index in the 'played' array for the card played by this
player.  It is undef if the player's teammate went alone.

'winCard' is the 0-based index of the winning card.  The mapping of
winning card index to winning player number may not be obvious due to
the possibility of players going alone, so both numbers are explicitly
provided.

'winner' is the 1-based number of the winning player.

=cut

sub endOfTrick {
   my $self = shift;
   my $state = shift;
   # do nothing
}

=item endOfHand STATEHASH

 {
   name        => 'Player 1',
   names       => {1 => 'Player 1', 2 => 'P2', 3 => 'P3', 4 => 'Fred'},
   number      => 1,
   ourTricks   => 3,
   theirTricks => 2,
   winType     => 'win',
   ourScore    => 8,
   theirScore  => 6,
   winScore    => 10,
   debug       => false,
 }

'winType' is one of: 'win', 'all', 'alone', 'euchre', which is 1, 2,
4, and 2 points respectively.

=cut

sub endOfHand {
   my $self = shift;
   my $state = shift;
   # do nothing
}

=item endOfGame STATEHASH

 {
   name        => 'Player 1',
   names       => {1 => 'Player 1', 2 => 'P2', 3 => 'P3', 4 => 'Fred'},
   number      => 1,
   ourScore    => 10,
   theirScore  => 6,
   debug       => false,
 }

=cut

sub endOfGame {
   my $self = shift;
   my $state = shift;
   # do nothing
}

=back

=head2 Miscellaneous AI Information

These methods are used to specify the programmatic behavior of your AI
across mutliple games.  Many AIs won't need this.

=over 4

=item persist

This method should return a boolean indicating whether the AI wants to
live longer than one game.  When a new game starts, this method is
called.  If it returns true, the instance is retained and the reset()
method is called.  If it returns false, the game will just call new()
again creating a new instance.  The default is falsee.  If you
override this to return true, you should override the reset() method
too.

=cut

sub persist {
   my $self = shift;

   return undef;
}

=item reset

Called to refresh the instance between games.

=cut

sub reset {
   my $self = shift;
}

=back

=head2 Utility Methods

These are routines of general convenience.  They are never called from
external objects.  They can be called as class methods or instance
methods.

=over 4

=item isLegalBid STATEHASH BID

Given a state hash and bid of the form described in the bid() method
above, return a boolean indicating whether that bid is valid.

=cut

sub isLegalBid {
   my $me = shift;
   my $state = shift;
   my $bid = shift;
   
   # Is it a pass?
   if (!defined $bid) {
      # Can't pass on the last bid if hang-the-dealer is in effect
      if ($state->{hangdealer} && $state->{passes} == 7) {
         return undef;
      } else {
         return $me;
      }
   }

   # Is is a valid bid?
   return undef if ($bid !~ /^([HSDCN])(|A)$/i);

   my $suit = uc($1);
   my $alone = $2;

   # Is it no trump?
   if ($suit eq "N") {
      # NT must be enable to call it
      return undef if (!$state->{notrump});
   }

   # Must call THE suit in the first round
   if ($state->{passes} < 4) {
      unless ($state->{turnedUp} =~ /(.)$/) {
         die "Missing suit on turned up card!?!?!?";
      }
      my $topsuit = $1;
      return undef if ($suit ne $topsuit);
   }

   return $me;
}

=item isLegalPlay STATEHASH CHOICE

Given a state hash and a hand index of the form described in the
playCard() method above, return a boolean indicating whether that
choice of plays is valid.

=cut

sub isLegalPlay {
   my $me = shift;
   my $state = shift;
   my $choice = shift;

   my $card = $state->{hand}->[$choice];
   return undef if (!$card);

   # Is it the first card led?
   my $cards = $state->{played};
   my $leadcard = $cards->[0];
   return $me if (!$leadcard);  # lead card can be anything

   # Is it following suit?
   my $cardsuit = $me->getCardSuit($state, $card);
   my $leadsuit = $me->getCardSuit($state, $leadcard);
   return $me if ($cardsuit eq $leadsuit);

   # Is the player out of the lead suit?
   my $hasLeadSuit = undef;
   foreach my $card (@{$state->{hand}}) {
      my $cardsuit = $me->getCardSuit($state, $card);
      if ($cardsuit eq $leadsuit) {
         $hasLeadSuit = $me;
         last;
      }
   }
   return !$hasLeadSuit;
}

=item getCardSuit STATEHASH CARD

Given a state hash from either any of the above action methods
[e.g. bid(), pickItUp() or playCard()], return the suit of a card,
properly accounting for suit of the left jack if trump has been
called.  The card argument should be in the form of '10C' or 'KD'.  The return value will be one of 'H', 'C', 'S' or 'D'.

=cut

sub getCardSuit {
   # report suit, or trumpsuit for left jack
   my $me = shift;
   my $state = shift;
   my $card = shift;

   $card =~ /^(.*)(.)$/;
   my $cardvalue = $1;
   my $cardsuit = $2;
   my %othertrump = ("H" => "D", "D" => "H", "S" => "C", "C" => "S");
   my $othertrump = $othertrump{$state->{trump} || ""};  # undef is notrump
   if ($othertrump && $cardsuit eq $othertrump && $cardvalue eq "J") {
      $cardsuit = $state->{trump};
   }
   return $cardsuit;
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
