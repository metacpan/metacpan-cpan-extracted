package Game::Checkers::Error;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

our (@FLAGS, %MESSAGE);

# has is installed through BEGIN::Lift, so it runs at compile time: a list it is
# given must be built at compile time too
BEGIN {
	@FLAGS = qw/
		game_over
		not_a_move
		not_your_piece
		must_capture
		wrong_direction
		occupied
		not_legal
		ambiguous
		no_offer
		nothing_to_undo
	/;

	%MESSAGE = (
		game_over => 'the game is over',
		not_a_move => 'that is not a move',
		not_your_piece => 'you have no piece on that square',
		must_capture => 'a capture is available, so it must be taken',
		wrong_direction => 'a man cannot move backwards',
		occupied => 'that square is not empty',
		not_legal => 'that is not a legal move',
		ambiguous => 'that could be more than one move, so give the whole path',
		no_offer => 'there is no draw to accept',
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
	default => []
);

sub throw {
	my ($class, $flag, %extra) = @_;
	die "'$flag' is not an error flag" unless $MESSAGE{$flag};
	return $class->new(
		$flag => 1,
		message => $MESSAGE{$flag},
		%extra
	);
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

Game::Checkers::Error - what a move was refused for

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	my $move = $game->move('11-16');

	if (ref $move eq 'Game::Checkers::Error') {
		print $move->message, "\n";
		print "you could play: ", join(', ', @{$move->legal}), "\n"
			if @{$move->legal};
	}

=head1 DESCRIPTION

A player's mistake is returned, never thrown: L<Game::Checkers/move> gives back
one of these instead of a L<Game::Checkers::Move>, in the shape
L<Game::Cribbage::Error> uses. Only a programmer error dies, and a square outside
1 to 32 or a colour that is not black or white is a programmer error.

Every error carries the flag for what went wrong, a sentence for a person, and
the moves that were available instead, because both the terminal and a web client
want to show them.

=head1 PROPERTIES

=head2 error

Readonly, always true, so a caller can test one thing whatever went wrong.

	$error->error;

=head2 message

Readonly string, one sentence for a person.

	$error->message;

=head2 legal

Readonly arrayref of the L<Game::Checkers::Move> objects that were legal instead.
For an ambiguous move it is the moves the notation matched.

	$error->legal;

=head2 game_over

The game had already finished.

=head2 not_a_move

The string or hashref did not parse as a move at all.

=head2 not_your_piece

The square is empty or holds the other side's piece.

=head2 must_capture

A simple move was offered while a jump was available. Capture is compulsory.

=head2 wrong_direction

A man was moved backwards.

=head2 occupied

The destination square is not empty.

=head2 not_legal

The move parsed, and it was the right player's piece, but it is not in the legal
list. A jump over your own piece, a two square slide, and a multi jump stopped
part way all arrive here.

=head2 ambiguous

The short form of a jump matched more than one legal sequence. Give the whole
path.

=head2 no_offer

A draw was accepted or declined when none had been offered.

=head2 nothing_to_undo

L<Game::Checkers/undo> was called on a game that has not moved.

=head1 FUNCTIONS

=head2 throw

Class method building an error from a flag, despite the name: it returns the
error rather than dying, because that is the contract. Extra arguments are passed
to the constructor, so C<legal> can be overridden.

	Game::Checkers::Error->throw('must_capture', legal => $moves);

=head2 code

The name of the flag that is set, which is what a web layer turns into an error
code.

	$error->code;   # 'must_capture'

=head2 stringify

The same as L</message>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-checkers at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Checkers>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Checkers

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Checkers>

=item * Search CPAN

L<https://metacpan.org/release/Game-Checkers>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
