package Game::Reversi::Error;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

our (@FLAGS, %MESSAGE);

BEGIN {
	@FLAGS = qw/
		not_centre
		square_taken
		not_your_turn
		no_flip
		has_move
		game_over
	/;

	%MESSAGE = (
		not_centre    => 'the first four discs go in the centre four',
		square_taken  => 'that square is already taken',
		not_your_turn => 'it is not your turn',
		no_flip       => 'that move outflanks nothing',
		has_move      => 'you have a move, so your turn cannot be forfeited',
		game_over     => 'the game is over',
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
		$flag   => 1,
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

sub flags { return [@FLAGS] }

sub stringify {
	my ($self) = @_;
	return ($self->code // 'error') . ': ' . ($self->message // '');
}

1;

__END__

=head1 NAME

Game::Reversi::Error - why a move was refused

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $error = Game::Reversi::Opening->check($board, $square);
    if ($error) {
        warn $error->code;        # 'not_centre'
        warn $error->message;     # 'the first four discs go in the centre four'
    }

=head1 DESCRIPTION

A refusal, B<returned rather than thrown>. Every rejection a player can cause
comes back as one of these, so a caller tests a return value instead of wrapping
a move in C<eval>. C<die> is kept for programmer error: a move that came out of
C<legal> and was then refused is a fault in the code, not in the player.

=head2 The flag list grows a phase at a time

Every flag is reachable from a real refusal and the suite asserts each one. A
code nothing can produce is dead weight, and here it is worse than that: the
site adapter maps every flag onto one of its own error codes, so an unreachable
flag becomes an unreachable row in a table somebody has to keep.

=head1 METHODS

=head2 not_centre, square_taken, not_your_turn, no_flip, has_move, game_over

One predicate per flag: true on the error that carries it, false otherwise.
B<This list has to be kept in step with C<@FLAGS>>, and C<t/pod-coverage.t> is
what notices when it is not, since each flag becomes an accessor.

=head2 throw

Builds the error for a flag, filling in its message. Dies on a flag that is not
in the list, because that is a typo rather than a refusal.

=head2 code

The flag that is set.

=head2 message

The sentence for it.

=head2 legal

What could have been done instead, where the caller supplied it.

=head2 flags

Every flag this class knows.

=head2 error

Always true, so a caller can test the returned value directly.

=head2 stringify

The code and the message together.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
