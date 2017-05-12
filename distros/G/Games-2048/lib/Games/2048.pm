=head1 NAME

Games::2048 - An ASCII clone of the 2048 game

=head1 SYNOPSIS

 use Games::2048;
 Games::2048->new->run;

=head1 DESCRIPTION

This module is a full clone of the L<2048 game by Gabriele Cirulli|http://gabrielecirulli.github.io/2048/>. It runs at the command-line, complete with controls identical to the original, a colorful interface, and even some text-based animations! It should work on Linux, Mac, and Windows.

Once installed, run the game with the command:

 2048

=head1 TODO

=over

=item * Add slide and merge animations

=item * Test on more systems and terminals

=back

=head1 AUTHOR

Blaise Roth <blaizer@cpan.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (C) 2015 by Blaise Roth.

This is free software; you can redistribute and/or modify it under
the same terms as the Perl 5 programming language system itself.

See L<http://dev.perl.org/licenses/> for more information.

=cut

package Games::2048;
use 5.012;
use Moo;
use mro; # enable next::method globally
use Scalar::Util qw/blessed/;

our $VERSION = '0.10';

use constant FRAME_TIME => 1/15;

use Games::2048::Util;
use Games::2048::Serializable;
use Games::2048::Animation;
use Games::2048::Tile;
use Games::2048::Grid;
use Games::2048::Board;
use Games::2048::Game;
use Games::2048::Game::Input;

has game       => is => 'rw';
has game_class => is => 'rw', default => 'Games::2048::Game::Input';
has game_file  => is => 'rw', default => 'game.dat';

has quit       => is => 'rw', default => 0;
has restart    => is => 'rw', default => 0;
has first_time => is => 'rw', default => 1;

has no_frame_delay  => is => 'rw', default => 0;
has no_restore_game => is => 'rw', default => 0;
has no_save_game    => is => 'rw', default => 0;

sub run {
	my $self = shift;

	$self->quit(0);
	Games::2048::Util::update_window_size;

	while (!$self->quit) {
		$self->restore_game if $self->first_time and !$self->no_restore_game;
		$self->new_game;

		$self->game->draw_welcome if $self->first_time;
		$self->game->draw;

		$self->first_time(0);

		# initialize the frame delay
		Games::2048::Util::frame_delay if !$self->no_frame_delay;

		while (1) {
			unless ($self->game->lose || $self->game->win) {
				$self->game->handle_input($self);
			}

			$self->game->draw(1);

			if ($self->quit or $self->restart
				or $self->game->lose || $self->game->win && !$self->game->needs_redraw
			) {
				last;
			}

			Games::2048::Util::frame_delay(FRAME_TIME) if !$self->no_frame_delay;
		}

		$self->game->draw_win;
		$self->save_game if $self->game->lose and !$self->no_save_game;

		unless ($self->quit or $self->restart) {
			$self->game->draw_win_question;
			$self->game->handle_finish($self);
			$self->game->draw_win_answer(!$self->quit);
		}
	}

	say "";
	$self->save_game if !$self->no_save_game;
}

sub new_game {
	my $self = shift;

	if (!$self->restart and $self->game and $self->game->is_valid and !$self->game->lose) {
		# this game is still going, so we use it as our new game
		$self->game->win(0);
		return;
	}

	$self->restart(0);

	my @options;
	if ($self->game) {
		@options = (
			Games::2048::Util::maybe(best_score    => $self->game->best_score),
			Games::2048::Util::maybe(no_animations => $self->game->no_animations),
			Games::2048::Util::maybe(zoom          => $self->game->zoom),
			Games::2048::Util::maybe(colors        => $self->game->colors),
		);
	}

	my $game_class = $self->game_class;
	$self->game($game_class->new(@options));

	$self->game->insert_start_tiles;
}

sub restore_game {
	my $self = shift;

	my $game_class = $self->game_class;
	$self->game($game_class->restore($self->game_file));

	if (!$self->game or !blessed $self->game or ref $self->game ne $self->game_class) {
		$self->game(undef);
		return;
	}
}

sub save_game {
	my $self = shift;
	$self->game->save($self->game_file);
}

1;
