package Game::Cribbage;

use strict;
use warnings;

our $VERSION = "0.02";

1;

__END__

=head1 NAME

Game::Cribbage - Cribbage game engine

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

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
