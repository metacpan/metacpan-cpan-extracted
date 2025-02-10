use 5.38.0;
use experimental 'class';

package Game::Floppy 0.07;
class Game::Floppy {
	our $VERSION = 0.07;
	use Raylib::App;
	use Raylib::FFI;
	use Raylib::Color;
	use Raylib::Keyboard;
	use Game::Floppy::Bird;
	use Game::Floppy::Tube;
	use Game::Floppy::Sprite;

	field $floppy_radius : param = 24;
	field $tubes_width : param = 80;
	field $width : param = 516;
	field $height : param = 400;
	field $fps : param = 20;

	field $frame;	
	field $game_over = 0;
	field $pause = 0;
	field $score = 0;
	field $hi_score = 0;
	field $floppy;
	field @tubes;

	method run {
		my $app = Raylib::App->window( $width, $height, 'Floppy' );
		$app->fps($fps);
		$floppy = Game::Floppy::Bird->new(
			x => 80,
			y => $height / 2 - $floppy_radius,
			width => $floppy_radius,
			height => $floppy_radius
		);

		my $background = Game::Floppy::Sprite->new(
			image => 'resources/background-day.png',
			x => 0,
			y => 0,
		);

                my $keyboard = Raylib::Keyboard->new(
                        key_map => {
                                # vim keys
                                KEY_SPACE() => sub { 
					if ($game_over) {
						$score = 0;
						@tubes = ();
						$floppy->y( $height / 2 - $floppy_radius );
						$game_over = 0;
 					} else {
						$self->handle_click();
					}
				},
                        },
                );

		while (!$app->exiting) {
			$app->draw(
				sub {
					$frame++;
					$app->clear();
					$background->draw(0, 0, $width, $height);

					if (IsMouseButtonReleased(0)) {
						$self->handle_click();
					}
					$keyboard->handle_events();
					
					if ($game_over) {

						DrawText( "Current Score: $score High Score: $hi_score", 10, 10, 22, Raylib::Color::WHITE );
						DrawText( "Game Over", 10, 40, 22, Raylib::Color::WHITE );

						DrawText( "Press space to try again", 10, 70, 22, Raylib::Color::WHITE );
						return;
					}
					$self->handle_flappy();
					$self->handle_tubes();
				
					DrawText( "Current Score: $score High Score: $hi_score", 10, 10, 22, Raylib::Color::WHITE );
				}
			);
		}
	}

	method handle_click () {
		$floppy->y($floppy->y - 30);
		$floppy->sprite->rotate(-45);
	}

	method handle_flappy () {
		$floppy->y($floppy->y + 3);
		$floppy->draw();
		if ($floppy->y > $height || $floppy->y < 0) {
			$game_over = 1;
		}
	}

	method handle_tubes () {
		for (reverse @tubes) {
			$_->x($_->x - 3);
			$_->draw();

			if ($_->check_collision($floppy)) {
				$game_over = 1;
				return;
			}
			
			if (($_->x + $_->width < $floppy->x) && $_->active) {
				$score += 100;
				$_->active(0);
				if ($score > $hi_score) {
					 $hi_score = $score;
				}
				shift @tubes if scalar @tubes;
			}


		}

		if ($frame % 100 == 0) {
			push @tubes, Game::Floppy::Tube->new(
				x => $width,
				y => 0,
				width => 50,
				height => int(rand($height - 100))
			); 
		}

	}

}

1;


=head1 NAME

Game::Floppy - Floppy bird using raylib

=head1 VERSION

Version 0.07

=cut


=head1 SYNOPSIS

	lnation$ floppy.pl
	...
	use Game::Floppy;
	my $floppy = Game::Floppy->new();
	$floppy->run();

=for html <img style="width:500px" src="https://raw.githubusercontent.com/ThisUsedToBeAnEmail/Game-Floppy/master/floppy.png" title="img-tag, local-dist" alt="Inlineimage" />

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-floppy at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Floppy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Floppy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Floppy>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Game-Floppy>

=item * Search CPAN

L<https://metacpan.org/release/Game-Floppy>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Game::Floppy
