package Games::Euchre::Team;

=head1 NAME

Games::Euchre::Team - Team class for Euchre card game

=head1 DESCRIPTION

The Team object is used to keep track of bidding information and
current score for the two teams in a Euchre game.

=cut

use strict;
use warnings;

=head1 CLASS METHODS

=over 4

=item new GAME NUMBER NAME PLAYER1 PLAYER2

Create and initialize a new Euchre team for the specified game.  The
number is "1" or "2".  The name is a string used to identify this
team.  The players are instantiated Games::Euchre::Player instances.

=cut

sub new {
   my $pkg = shift;
   my $game = shift;
   my $number = shift; # 1-based
   my $name = shift;
   my $player1 = shift;
   my $player2 = shift;
   return bless({
      game => $game,
      number => $number,
      name => $name,
      players => [$player1,$player2],
      points => undef,
      tricks => undef,
      otherTeam => undef,
   }, $pkg);
}

=back

=head1 INSTANCE METHODS

=over 4

=item getGame

Return the Euchre game instance to which this team belongs.

=cut

sub getGame {
   my $self = shift;
   return $self->{game};
}

=item getOtherTeam

Returns the team recorded in the setOtherTeam() method.

=cut

sub getOtherTeam {
   my $self = shift;
   # Other team's 0-based index is this team's 1-based number mod 2
   # i.e. 1 -> 1, 2-> 0
   return ($self->getGame()->getTeams())[$self->getNumber()%2];
}

=item addScore SCORE

Increment this team's game score by this amount.

=cut

sub addScore {
   my $self = shift;
   my $score = shift;
   $self->{points} += $score;
   return $self;
}

=item addTrick

Increment this team's trick count by one.

=cut

sub addTrick {
   my $self = shift;
   $self->{tricks}++;
   return $self;
}

=item getNumber

Return this team's number, between 1 and 2

=cut

sub getNumber {
   my $self = shift;
   return $self->{number};
}

=item getName

Return the team name.

=cut

sub getName {
   my $self = shift;
   return $self->{name};
}

=item getPlayers

Return an array of the two players on this team.

=cut

sub getPlayers {
   my $self = shift;
   return @{$self->{players}};
}

=item getScore

Return the current game score for this team.\

=cut

sub getScore {
   my $self = shift;
   return $self->{points};
}

=item getTricks

Return the number of tricks won by this team in the current hand.

=cut

sub getTricks {
   my $self = shift;
   return $self->{tricks};
}

=item wentAlone

Returns a boolean indicating whether a member of this team chose to go
alone on a bid.

=cut

sub wentAlone {
   my $self = shift;
   my $alone = undef;
   foreach my $player ($self->getPlayers()) {
      $alone ||= $player->wentAlone();
   }
   return $alone;
}

=item isBidder

Returns a boolean indicating whether a member of this team called the
trump suit during bidding.

=cut

sub isBidder {
   my $self = shift;
   my $bid = undef;
   foreach my $player ($self->getPlayers()) {
      $bid ||= $player->isBidder();
   }
   return $bid;
}

=item resetGame

Clear all of the state for the current game and get ready for the next one.

=cut

sub resetGame {
   my $self = shift;
   $self->{points} = 0;
   return $self->resetHand();
}

=item resetHand

Clear all of the state for the current hand and get ready for the next one.

=cut

sub resetHand {
   my $self = shift;
   $self->{tricks} = 0;
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
