package Game::Cribbage;

use strict;
use warnings;

our $VERSION = "0.18";

use Game::Cribbage::Terminal;

sub start {
	my ($class, @args) = @_;
	return Game::Cribbage::Terminal->new(@args)->start;
}

1;

__END__

=head1 NAME

Game::Cribbage - Cribbage game engine

=head1 VERSION

Version 0.18

=cut

=head1 SYNOPSIS

	lnation$ cribbage

	...

	use Game::Cribbage;

	my $status = Game::Cribbage->start;          # arrow keys if the terminal has them
	my $status = Game::Cribbage->start(picking => 0);   # type the numbers

	...

=for html <img style="width:500px" src="https://raw.githubusercontent.com/ThisUsedToBeAnEmail/Game-Cribbage/main/test.png" title="img-tag, local-dist" alt="Inlineimage" />

	...

	use Game::Cribbage::Board;

	my $engine = Game::Cribbage::Board->new();

	$engine->add_player(name => 'Robert');
	$engine->add_player(name => 'Joseph');

	$engine->start_game();

	# low card logic to then set the dealer/crib player
	$engine->set_crib_player('player1');

	# deal hands
	$engine->draw_hands();

	$engine->crib_player_cards('player1', $cards);
	$engine->crib_player_cards('player2', $cards);

	# split to get starter
	$engine->add_starter_card('player2', $card);

	$engine->play_card('player1', $card);
	$engine->play_card('player2', $card);

	...

	$engine->next_play();

	...

	$engine->end_hands();
	$engine->score;

=head1 DESCRIPTION

Cribbage is a card game, typically for two players, where the goal is to be the first to reach 121 points by forming counting combinations of cards and using a special pegging board to track scores.

The L<Game::Cribbage> class is an implementation of cribbage using the terminal. The distribution itself is an game engine and should contain all the logic you need to build a version of Cribbage using any alternative interface.

=head1 FUNCTIONS

=head2 start

	my $status = Game::Cribbage->start(picking => 0);

Plays a game on the terminal and returns the exit status: C<0> if you won or
quit, C<1> if you lost. A convenience front door, and the only method this
module has; every argument is handed to L<Game::Cribbage::Terminal/new>, which
is where the screen, the keys and the game loop all live.

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

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Game-Cribbage>

=item * Search CPAN

L<https://metacpan.org/release/Game-Cribbage>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
