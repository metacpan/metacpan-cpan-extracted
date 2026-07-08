package Game::Cribbage::Play::Card;

use strict;
use warnings;

use Object::Proto::Sugar -types;

has [qw/player card/] => (
	is => 'ro',
	isa => Object
);

sub value {
	$_[0]->card->value;
}

sub symbol {
	$_[0]->card->symbol;
}

1;

__END__

=head1 NAME

Game::Cribbage::Play::Card - a card as it appears within a play sequence

=head1 VERSION

Version 0.12

=cut

=head1 SYNOPSIS

	use Game::Cribbage::Play::Card;

	my $play_card = Game::Cribbage::Play::Card->new(
		player => 'player1',
		card   => $deck_card,
	);

	print $play_card->value;   # delegates to the wrapped Deck::Card
	print $play_card->symbol;  # delegates to the wrapped Deck::Card

=head1 DESCRIPTION

Wraps a L<Game::Cribbage::Deck::Card> together with the identity of the player
who played it, so that a L<Game::Cribbage::Play> object can track the ordered
sequence of played cards alongside their owners.

=head1 PROPERTIES

=head2 player

Readonly object or string identifying the player who played this card.

	$play_card->player;

=head2 card

Readonly L<Game::Cribbage::Deck::Card> object that this play-card wraps.

	$play_card->card;

=head1 FUNCTIONS

=head2 value

Delegates to the wrapped card's C<value> method, returning the pip value used
for totalling the running count (A=1, 2-10 face value, J/Q/K=10).

	$play_card->value;

=head2 symbol

Delegates to the wrapped card's C<symbol> method, returning the card symbol
string (e.g. C<'A'>, C<'7'>, C<'K'>).

	$play_card->symbol;

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
