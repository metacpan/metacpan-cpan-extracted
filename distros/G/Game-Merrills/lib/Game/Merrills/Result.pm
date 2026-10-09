package Game::Merrills::Result;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

our (@REASONS, %REASON);

BEGIN {
	@REASONS = qw/few blocked repetition no_mill agreement resign timeout/;
	%REASON = map { $_ => 1 } @REASONS;
}

has winner => (
	is => 'ro'
);

has reason => (
	is => 'ro',
	isa => Str
);

sub BUILD {
	my ($self) = @_;
	my $reason = $self->reason;
	die 'reason must be one of ' . join(', ', @REASONS) . ', got '
		. (defined $reason ? "'$reason'" : 'undef')
		unless defined $reason && $REASON{$reason};
	my $winner = $self->winner;
	die "winner must be white, black or undef for a draw, got '$winner'"
		if defined $winner && $winner ne 'white' && $winner ne 'black';
	my $drawn = $reason eq 'repetition' || $reason eq 'no_mill' || $reason eq 'agreement';
	die "a game that ends by $reason is a draw and has no winner"
		if $drawn && defined $winner;
	die "a game that ends by $reason has a winner"
		if !$drawn && !defined $winner;
	return $self;
}

sub reasons {
	return @REASONS;
}

sub is_draw {
	return defined $_[0]->winner ? 0 : 1;
}

sub loser {
	my ($self) = @_;
	return undef if $self->is_draw;
	return $self->winner eq 'white' ? 'black' : 'white';
}

sub stringify {
	my ($self) = @_;
	my $reason = $self->reason;
	return 'Draw: agreed' if $reason eq 'agreement';
	return 'Draw: the same position three times' if $reason eq 'repetition';
	return 'Draw: too long without a mill' if $reason eq 'no_mill';
	my $loser = ucfirst $self->loser;
	my $winner = ucfirst $self->winner;
	return "$winner wins: $loser has fewer than three men" if $reason eq 'few';
	return "$winner wins: $loser has no move" if $reason eq 'blocked';
	return "$winner wins: $loser resigned" if $reason eq 'resign';
	return "$winner wins: $loser ran out of time";
}

1;

__END__

=head1 NAME

Game::Merrills::Result - how a game ended

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	my $result = $game->result;

	$result->winner;           # 'white'
	$result->loser;            # 'black'
	$result->reason;           # 'few'
	$result->is_draw;          # 0
	$result->stringify;        # 'White wins: Black has fewer than three men'

=head1 DESCRIPTION

A game that has ended has one of these, and a game still going has none.

=head2 The reasons

=over 4

=item few

The loser was brought down to two men, counting those still in hand, and can
no longer make a mill.

=item blocked

It was the loser's turn and no man of theirs could move.

=item repetition

A draw: the same men stood on the same points with the same side to move for
the third time.

=item no_mill

A draw: too many moves in a row went by without either side closing a mill.

=item agreement

A draw: one side offered it and the other accepted.

=item resign

The loser gave up.

=item timeout

The loser ran out of time. The game keeps no clock; whoever does tells it.

=back

=head1 PROPERTIES

Both are read only. A result that contradicts itself, a draw with a winner or
a win without one, dies on construction.

=head2 winner

The side that won, C<white> or C<black>, or undef for a draw.

	$result->winner;

=head2 reason

One of the reasons above.

	$result->reason;

=head1 METHODS

=head2 reasons

Every reason, as a list.

	my @reasons = Game::Merrills::Result->reasons;

=head2 is_draw

True when nobody won.

	$result->is_draw;

=head2 loser

The side that lost, or undef for a draw.

	$result->loser;

=head2 stringify

The result as a line to show a person.

	$result->stringify;        # 'Draw: the same position three times'

=head1 PACKAGE VARIABLES

=over 4

=item C<@REASONS>

The reasons, in order.

=item C<%REASON>

The same, as the keys of a hash.

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
