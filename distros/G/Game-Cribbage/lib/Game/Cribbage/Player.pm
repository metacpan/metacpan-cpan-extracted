package Game::Cribbage::Player;

use strict;
use warnings;

use Object::Proto::Sugar -types;

has [qw/id number/] => (
	is => 'ro',
	isa => Int
);

has name => (
	is => 'ro',
	isa => Str
);


sub player {
	return 'player' . $_[0]->number;
}

1;

__END__

=head1 NAME

Game::Cribbage::Player - a player in a cribbage game

=head1 VERSION

Version 0.12

=cut

=head1 SYNOPSIS

	use Game::Cribbage::Player;

	my $player = Game::Cribbage::Player->new(
		id     => 1,
		number => 1,
		name   => 'Alice',
	);

	print $player->player;  # 'player1'

=head1 PROPERTIES

=head2 id

Readonly integer property holding the player's database or external identifier.
May be undef if persistence is not used.

	$player->id;

=head2 number

Readonly integer property holding the player's seat number (1-based) for the
current game. Used to derive the internal player key.

	$player->number;

=head2 name

Readonly string property holding the player's display name.

	$player->name;

=head1 FUNCTIONS

=head2 player

Returns the internal player identifier string derived from the seat number,
e.g. C<'player1'>, C<'player2'>. This key is used throughout the engine to
look up per-player data inside L<Game::Cribbage::Hands> and related objects.

	$player->player;  # 'player1'

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
