package Game::Dominoes::Error;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

our (@FLAGS, %MESSAGE);

BEGIN {
	@FLAGS = qw/
		not_your_turn
		tile_not_held
		end_mismatch
		no_such_arm
		arm_closed
		game_over
		bad_move
	/;

	%MESSAGE = (
		not_your_turn => 'it is not your turn',
		tile_not_held => 'you do not hold that tile',
		end_mismatch  => 'that tile does not match that end',
		no_such_arm   => 'there is no such arm',
		arm_closed    => 'that arm is not open yet',
		game_over     => 'the game is over',
		bad_move      => 'that is not a move',
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

sub flags {
	return [@FLAGS];
}

sub stringify {
	my ($self) = @_;
	return ($self->code // 'error') . ': ' . ($self->message // '');
}

1;

__END__

=head1 NAME

Game::Dominoes::Error - why a move was refused

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	my $out = $game->play(1, '6-4@L');

	if (ref $out eq 'Game::Dominoes::Error') {
	    $out->code;       # 'tile_not_held'
	    $out->message;    # 'you do not hold that tile'
	}

=head1 DESCRIPTION

B<Returned, never thrown.> Every rejection a player can cause comes back as one
of these, so a caller tests the return value and never has to wrap a play in an
C<eval>. C<die> is kept for programmer error: a seat that does not exist, a
face outside 0 to 6, a variant nobody defined.

One flag is set per error. The flag is the thing to switch on, and
L<P2PGames::Game::Dominoes> maps it onto a
L<P2PGames::Game::Illegal> code through one table, so nothing engine-shaped
escapes into the site.

This is the shape L<Game::Cribbage::Error> and L<Game::Checkers::Error> use.

=head1 PROPERTIES

=head2 error

	$error->error;   # always 1

There so that a caller with a value that is either a result or an error can
ask one question about it.

=head2 message

	$error->message;

The sentence for a person, already filled in from the flag.

=head2 legal

	$error->legal;

What the seat could have done instead, when saying so is cheap. An arrayref,
empty by default.

=head2 not_your_turn, tile_not_held, end_mismatch, no_such_arm, arm_closed, game_over, bad_move

The flags. Exactly one is set, and every one of them is reachable from a real
refusal, which C<t/11-legal.t> asserts one at a time.

There is no flag for drawing or passing wrongly, and none for playing between
hands, because L<Game::Dominoes> resolves a forced turn itself: drawing is
never a move a caller makes, so it can never be refused, and a hand boundary is
crossed inside the play that causes it.

=head1 FUNCTIONS

=head2 throw

	return Game::Dominoes::Error->throw('tile_not_held');

B<Returns> the error. The name is kept from the classes this follows, and it
is a lie about the control flow on purpose: renaming it would break the shape
every other engine here uses. Dies only if the flag does not exist, which is a
typo in the engine and not a move.

=head2 code

	$error->code;   # 'tile_not_held'

The one flag that is set.

=head2 flags

	Game::Dominoes::Error->flags;

Every flag this class can carry, as an arrayref, so a test can assert that
each one is reachable from a real refusal.

=head2 stringify

	$error->stringify;   # 'tile_not_held: you do not hold that tile'

=head1 SEE ALSO

L<Game::Dominoes>, which returns these.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-dominoes at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Dominoes>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Game::Dominoes::Error

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
