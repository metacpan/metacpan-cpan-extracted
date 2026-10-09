package Game::Merrills::Error;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

our (@FLAGS, %MESSAGE);

BEGIN {
	@FLAGS = qw/
		game_over
		not_a_move
		men_in_hand
		no_men_in_hand
		not_your_man
		occupied
		not_adjacent
		must_remove
		nothing_to_remove
		no_man_there
		man_in_mill
		not_legal
		no_offer
		nothing_to_undo
	/;

	%MESSAGE = (
		game_over => 'the game is over',
		not_a_move => 'that is not a move',
		men_in_hand => 'you still have men to place, so place one',
		no_men_in_hand => 'every man is placed, so move one',
		not_your_man => 'you have no man on that point',
		occupied => 'that point is not empty',
		not_adjacent => 'a man moves along a line to the next point',
		must_remove => 'that closes a mill, so say which man you take',
		nothing_to_remove => 'that closes no mill, so it takes no man',
		no_man_there => 'there is no man of theirs on that point to take',
		man_in_mill => 'a man in a mill is safe while another stands outside one',
		not_legal => 'that is not a legal move',
		no_offer => 'there is no draw to answer',
		nothing_to_undo => 'there is nothing to undo',
	);
}

has [@FLAGS] => (
	is => 'ro'
);

has error => (
	is => 'ro',
	default => 1
);

has message => (
	is => 'ro',
	isa => Str
);

has legal => (
	is => 'ro',
	isa => ArrayRef,
	default => sub { [] }
);

sub throw {
	my ($class, $flag, %extra) = @_;
	die "'" . (defined $flag ? $flag : 'undef') . "' is not an error flag"
		unless defined $flag && $MESSAGE{$flag};
	return $class->new(
		$flag => 1,
		message => $MESSAGE{$flag},
		%extra
	);
}

sub flags {
	return @FLAGS;
}

sub messages {
	return {%MESSAGE};
}

sub code {
	my ($self) = @_;
	for my $flag (@FLAGS) {
		return $flag if $self->$flag;
	}
	return undef;
}

sub stringify {
	return $_[0]->message;
}

1;

__END__

=head1 NAME

Game::Merrills::Error - a move the game refused, and why

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	my $move = $game->move('d2-d4');

	if (ref $move eq 'Game::Merrills::Error') {
		$move->code;                 # 'not_a_move'
		$move->message;              # 'that is not a move'
		$move->not_a_move;           # 1
		$move->legal;                # what could be played instead
	}

=head1 DESCRIPTION

When a player asks for something the rules do not allow, the game does not
die. It hands back one of these in place of the move, and the game is left
exactly as it was.

Every refusal has one flag set, a name for the reason that code can test, and
a message a person can read. The message is a sentence without its capital or
its full stop, so it can be put into a longer one.

C<throw> is the house's name for making one. It returns the object and does
not die.

=head2 The reasons

=over 4

=item game_over

The game has ended.

=item not_a_move

What was asked for could not be read as a move at all.

=item men_in_hand

A man was moved while the side still has men to place.

=item no_men_in_hand

A man was placed when the side has none left in hand.

=item not_your_man

The point to move from holds no man of the side to move.

=item occupied

The point to land on is not empty.

=item not_adjacent

The man was moved to a point that is not next to it along a line, by a side
that may not fly.

=item must_remove

The move closes a mill and does not say which man it takes.

=item nothing_to_remove

The move names a man to take and closes no mill.

=item no_man_there

The point named to take from holds no enemy man.

=item man_in_mill

The man named is in a mill, and an enemy man outside any mill could be taken
instead.

=item not_legal

The move is not legal for a reason none of the others covers.

=item no_offer

A draw was accepted or declined that the other side had not offered.

=item nothing_to_undo

No move has been played, so none can be taken back.

=back

=head1 PROPERTIES

All are read only.

=head2 game_over

=head2 not_a_move

=head2 men_in_hand

=head2 no_men_in_hand

=head2 not_your_man

=head2 occupied

=head2 not_adjacent

=head2 must_remove

=head2 nothing_to_remove

=head2 no_man_there

=head2 man_in_mill

=head2 not_legal

=head2 no_offer

=head2 nothing_to_undo

One for each reason above, true on the refusal that has that reason and
undefined on every other.

	$error->occupied;

=head2 error

Always true, so that anything a game returns can be asked whether it is one.

	$error->error;

=head2 message

The reason, as a sentence without its capital or full stop.

	$error->message;

=head2 legal

An arrayref of the L<Game::Merrills::Move> objects that could have been
played instead. Empty when the game is over.

	$error->legal;

=head1 METHODS

=head2 throw

Makes a refusal from a flag, with anything further to set on it. Returns it.
Dies when the flag is not one of the reasons.

	my $error = Game::Merrills::Error->throw('occupied', legal => $moves);

=head2 flags

Every reason, as a list, in the order a refusal is searched for its code.

	my @flags = Game::Merrills::Error->flags;

=head2 messages

A hashref of the message for every reason, a fresh copy each time.

	my $messages = Game::Merrills::Error->messages;

=head2 code

The name of the reason.

	$error->code;                    # 'occupied'

=head2 stringify

The same as L</message>.

	$error->stringify;

=head1 PACKAGE VARIABLES

=over 4

=item C<@FLAGS>

The reasons, in order.

=item C<%MESSAGE>

The message for each reason.

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
