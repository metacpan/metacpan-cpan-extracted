use 5.38.0;
use experimental 'class';
our $VERSION = 0.03;
class Game::Snake {
	use Raylib::App;	
	use Raylib::FFI;
	use Raylib::Keyboard;
	use Game::Snake::Cell;
	use Game::Snake::Text;
	use Game::Snake::Head;
	use Game::Snake::Tail;
	use Game::Snake::Food;

	field $frame = 0;

	field $width : param = 800;
	field $height : param = 600;
	field $cell_size : param = 20;
	field $top_padding : param = 20;
	field $food_score : param  = 10;	

	field @grid;
	field %collide;
	field $game_over = 0;
	field $score = 0;
	field @snake;
	field $food;
	field $fps = 2;

	method reset_game () {
		$game_over = 0;
		$score = 0;
		$fps = 2;
		@snake = ();
		push @snake, Game::Snake::Head->new(
			x => 300,
			y => 400,
			width => $cell_size,
			height => $cell_size,
			direction => 'left'
		);
		push @snake, Game::Snake::Tail->new(
			x => 320,
			y => 400,
			width => $cell_size,
			height => $cell_size,
			direction => 'left'
		);
		push @snake, Game::Snake::Tail->new(
			x => 340,
			y => 400,
			width => $cell_size,
			height => $cell_size,
			direction => 'left'
		);
	}

	method run {
		my $app = Raylib::App->window( $width, $height, "Snake" );
		$app->fps($fps);
	
		$self->reset_game();

		my $score_text = Game::Snake::Text->new(
			x => 10,
			y => 10,
			size => 20,
		);

		my $gameover_text = Game::Snake::Text->new(
			x => 260,
			y => 280,
			size => 40,
		);

		my $keyboard = Raylib::Keyboard->new(
			key_map => {
				# vim keys
				KEY_W() => sub { $self->move('up') },
				KEY_S() => sub { $self->move('down') },
				KEY_A() => sub { $self->move('left') },
				KEY_D() => sub { $self->move('right') },
				# arrow keys
				KEY_UP()    => sub { $self->move('up') },
				KEY_DOWN()  => sub { $self->move('down') },
				KEY_LEFT()  => sub { $self->move('left') },
				KEY_RIGHT() => sub { $self->move('right') },
			
				KEY_ENTER() => sub { 
					if ($game_over) {
						$self->reset_game();
					}
				}
			},
		);

		$self->create_grid();

		while (!$app->exiting) {
			$app->draw(
				sub {
					$frame++;
					$app->fps($fps);
					$app->clear();
					$score_text->draw("Score: $score");

					$keyboard->handle_events();
					if ($game_over) {
						$gameover_text->draw("Game Over");
						return;
					}

					$self->show_grid();
					$self->draw_snake();
					$self->draw_food();
				}
			);
		}
	}

	method create_grid {
		for (my $y = $cell_size + $top_padding; $y < $height; $y += $cell_size) {
			for (my $x = 0; $x < $width; $x += $cell_size) {
				push @grid, Game::Snake::Cell->new(
					x => $x,
					y => $y,
					width => $cell_size,
					height => $cell_size
				);
			}
		}
        }

        method show_grid {
		for (@grid) {
			$_->draw();
		}
        }

	method move ($move) {
		my $head = $snake[0];
		if (
			$move eq $head->direction 
				|| ( $move eq 'right' && $head->direction eq 'left' ) 
				|| ( $move eq 'left' && $head->direction eq 'right' )
				|| ( $move eq 'up' && $head->direction eq 'down' )
				|| ( $move eq 'down' && $head->direction eq 'up' )
		) {
			return;
		}
		$head->direction($move);
	}

	method extend_snake {
		my $last = $snake[-1];
		my $x = $last->x;
		$x += $cell_size if ($last->direction eq 'left');
		$x -= $cell_size if ($last->direction eq 'right');
		my $y = $last->y;
		$y += $cell_size if ($last->direction eq 'up');
		$y -= $cell_size if ($last->direction eq 'down');
		
		push @snake, Game::Snake::Tail->new(
			x => $x,
			y => $y,
			width => $cell_size,
			height => $cell_size,
			direction => $last->direction
		);


		if ($score % 30 == 0) {
			$fps++;
		}

	}

	method draw_snake {
		%collide = ();
		my ($last);
		for (my $i = scalar @snake - 1; $i >= 0; $i--) {
			my $sn = $snake[$i];
			if ($sn->direction eq 'left') {
				$sn->x($sn->x - $cell_size);
			} elsif ($sn->direction eq 'right') {
				$sn->x($sn->x + $cell_size);
			} elsif ($sn->direction eq 'up') {
				$sn->y($sn->y - $cell_size);
			} elsif ($sn->direction eq 'down') {
				$sn->y($sn->y + $cell_size);
			}

			if ($i > 0) {
				$sn->bend( $snake[$i - 1]->direction ne $sn->direction ? $snake[$i - 1]->direction : 0 );
				$sn->last($i == $#snake ? 1 : 0 );
			}
			$sn->draw();
			if ($last) {
				$last->direction($sn->direction);
				$collide{$last->x}->{$last->y}++;
			}
			$last = $sn;
		}

		my $head = $snake[0];
		if (
			$collide{$head->x}->{$head->y}
				|| $head->x < 0
				|| $head->x > $width
				|| $head->y < $cell_size + $top_padding
				|| $head->y > $height

		) {
			$game_over = 1;
		}

		$collide{$head->x}->{$head->y}++;
	}

	method draw_food {
		if (!$food) {
			my $rand;
			while (!$rand) {
				$rand = $grid[int(rand(scalar(@grid)))];
				$rand = undef if $collide{$rand->x}->{$rand->y};
			}
			$food = Game::Snake::Food->new(
				x => $rand->x,
				y => $rand->y,
				height => $cell_size,
				width => $cell_size,
			);
		}
		
		if ($collide{$food->x}->{$food->y}) {
			$score += $food_score;
			$food = undef;
			$self->extend_snake;
			return;
		}

		$food->draw();
	}
	

}

1;

__END__

=head1 NAME

Game::Snake - A clone of the classic snake game using raylib

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

	lnation$ snake.pl

	...

	use Game::Snake;

	my $snake = Game::Snake->new();
	
	$snake->run();

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-snake at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Snake>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Snake

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Snake>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Game-Snake>

=item * Search CPAN

L<https://metacpan.org/release/Game-Snake>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Game::Snake
