package Game::Cribbage::Rounds;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Cribbage::Round;

has number => (
	is => 'ro',
	isa => Int
);

has history => (
	is => 'rw',
	isa => ArrayRef,
	default => []
);

has current_round => (
	is => 'rw',
	isa => Object,
);

sub next_round {
	my ($self, $game, %args) = @_;
	if (scalar @{$self->history} >= $self->number) {
		die 'DISPLAY THE RESULT FOR THE GAME';
	}
	my $round = Game::Cribbage::Round->new(
		number => scalar @{$self->history} + 1,	
		%args
	)->init($game);
	push @{$self->history}, $round;
	$self->current_round($round);
	return $self;
}

1;

__END__

=head1 NAME

Game::Cribbage::Rounds - collection of rounds for a full cribbage game

=head1 VERSION

Version 0.12

=cut

=head1 SYNOPSIS

	use Game::Cribbage::Rounds;

	my $rounds = Game::Cribbage::Rounds->new(number => 1);

	$rounds->next_round($game);

	my $round = $rounds->current_round;

=head1 DESCRIPTION

Manages the sequence of L<Game::Cribbage::Round> objects that make up a
complete game.  Enforces the maximum round count and tracks which round is
currently in progress.

=head1 PROPERTIES

=head2 number

Readonly integer property holding the total number of rounds allowed in the
game.  Attempting to start more rounds than this limit raises an exception.

	$rounds->number;

=head2 history

Read/write arrayref of all L<Game::Cribbage::Round> objects played so far,
in order from first to most recent.

	$rounds->history;

=head2 current_round

Read/write property holding the active L<Game::Cribbage::Round> object.

	$rounds->current_round;

=head1 FUNCTIONS

=head2 next_round

Creates a new L<Game::Cribbage::Round>, initialises it for C<$game>, pushes
it onto C<history>, and sets it as C<current_round>.  Accepts optional named
arguments (e.g. C<id>) that are forwarded to the Round constructor.  Dies if
the round limit has already been reached.

	$rounds->next_round($game);
	$rounds->next_round($game, id => 42);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-cribbage at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Cribbage>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Cribbage

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Cribbage>

=item * Search CPAN

L<https://metacpan.org/release/Game-Cribbage>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
