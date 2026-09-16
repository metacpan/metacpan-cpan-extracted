package Game::Reversi::Result;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

our @RESULTS;

BEGIN {
	@RESULTS = qw/score draw timeout abandoned resign/;
}

has winner => (
	is => 'ro'
);

has result => (
	is  => 'ro',
	isa => Str
);

has counts => (
	is  => 'ro',
	isa => HashRef
);

has score => (
	is => 'ro'
);

has places => (
	is  => 'ro',
	isa => HashRef
);

sub BUILD {
	my ($self) = @_;
	my $result = $self->result // '';
	die "Game::Reversi::Result: '$result' is not a result"
		unless grep { $_ eq $result } @RESULTS;
	die 'Game::Reversi::Result: a draw has no winner'
		if $result eq 'draw' && defined $self->winner;
	return $self;
}

sub results { return [ @RESULTS ] }

sub natural {
	my ($self) = @_;
	return ($self->result eq 'score' || $self->result eq 'draw') ? 1 : 0;
}

sub stringify {
	my ($self) = @_;
	my $score = $self->score;
	my $line = defined $self->winner ? uc($self->winner) . ' wins' : 'a tie';
	$line .= ', ' . $score->{b} . ' to ' . $score->{w} if $score;
	$line .= ' (' . $self->result . ')' unless $self->natural;
	return $line;
}

1;

__END__

=head1 NAME

Game::Reversi::Result - who won, by what, and for how much

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $result = $game->result;

    $result->winner;    # 'b', 'w', or undef for a tie
    $result->result;    # 'score' | 'draw' | 'timeout' | 'abandoned' | 'resign'
    $result->counts;    # discs on the board:   { b => 20, w => 14 }
    $result->score;     # the official score:   { b => 50, w => 14 }
    $result->places;    # { b => 1, w => 2 }

=head1 DESCRIPTION

=head2 counts and score are not the same number

C<counts> is what is on the board. C<score> is the official score, which awards
the empty squares to the winner and therefore always totals 64. A game ending
20-14 with thirty squares empty has C<counts> of 20 and 14 and a C<score> of 50
and 14. See L<Game::Reversi::Scoring>.

=head2 An interrupted game has no official score

C<score> is C<undef> unless L</natural> is true.

This is deliberate, and it is the one place where this distribution declines to
implement a rule. The sources give three different answers for a game stopped by
a clock. WOF's championship rules guarantee the non-defaulting player at least
33-31; the same document scores an abandoned game 64-0; and Wikipedia describes
a common over-the-board procedure guaranteeing only a one disc margin, while
conceding that "There are varying methods to determine the official score when a
player defaults."

B<A timeout is the host talking, not the game.> Whatever site or program is
running the game already has a policy for what happens when somebody stops
playing, and a rules engine that imposed a tournament convention on top of it
would be disagreeing with its host for a reason no player would understand. So
the result names the winner, C<counts> says what was on the board, and what that
is worth is the caller's decision.

This matters far more in correspondence play than over a board. Over a board a
default is rare; in a game played over days it is an ordinary way for a game to
end.

=head1 METHODS

=head2 winner

C<b>, C<w>, or C<undef> for a tie.

=head2 result

One of C<score>, C<draw>, C<timeout>, C<abandoned>, C<resign>.

=head2 counts

Discs on the board, by colour.

=head2 score

The official score, or C<undef> for an interrupted game.

=head2 places

Finishing order, C<1> for the winner and C<2> for the loser, with both C<1> on a
tie.

=head2 natural

Whether the game reached its own end rather than being stopped.

=head2 results

Every result value this class accepts.

=head2 stringify

A sentence.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
