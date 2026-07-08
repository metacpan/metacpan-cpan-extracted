package Game::Cribbage::Round::Score;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Cribbage::Error;

has [qw/player1 player2 player3 player4/] => (
	is => 'rw',
	isa => HashRef
);

1;

__END__

=head1 NAME

Game::Cribbage::Round::Score - running score tracker for a round

=head1 VERSION

Version 0.12

=cut

=head1 SYNOPSIS

	use Game::Cribbage::Round::Score;

	my $score = Game::Cribbage::Round::Score->new(
		player1 => { current => 0, last => 0 },
		player2 => { current => 0, last => 0 },
	);

	# award 6 points to player1
	$score->player1->{last}    = $score->player1->{current};
	$score->player1->{current} += 6;

=head1 DESCRIPTION

Holds the cumulative per-player scores for a single L<Game::Cribbage::Round>.
Each player slot stores a hashref with two keys:

=over 4

=item * C<current> - points earned so far in the round

=item * C<last> - points at the previous scoring event (used to detect a win)

=back

=head1 PROPERTIES

=head2 player1

Read/write hashref holding the current and last score for player 1.

	$score->player1->{current};
	$score->player1->{last};

=head2 player2

Read/write hashref holding the current and last score for player 2.

	$score->player2->{current};
	$score->player2->{last};

=head2 player3

Read/write hashref holding the current and last score for player 3 in a
three- or four-player game.

	$score->player3->{current};

=head2 player4

Read/write hashref holding the current and last score for player 4 in a
four-player game.

	$score->player4->{current};

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
