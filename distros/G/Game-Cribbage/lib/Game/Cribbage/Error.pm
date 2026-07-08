package Game::Cribbage::Error;

use strict;
use warnings;

use Object::Proto::Sugar;

has [qw/error message over go score/] => (
	is => 'ro',
);

1;

__END__

=head1 NAME

Game::Cribbage::Error - error object returned by game operations

=head1 VERSION

Version 0.12

=cut

=head1 SYNOPSIS

	use Game::Cribbage::Error;

	my $err = Game::Cribbage::Error->new(
		message => 'It is not the turn of player1',
	);

	if ($err->go) {
		# player must say go
	}

=head1 PROPERTIES

=head2 error

Readonly scalar flag indicating a generic error condition.

	$err->error;

=head2 message

Readonly scalar containing a human-readable description of the error.

	$err->message;

=head2 over

Readonly scalar flag set when a card play would take the running total over 31.

	$err->over;

=head2 go

Readonly scalar flag set when the play has reached 31 or no card can be played
without exceeding 31 (the player must say "go").

	$err->go;

=head2 score

Readonly scalar holding any score associated with the error condition.

	$err->score;

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
