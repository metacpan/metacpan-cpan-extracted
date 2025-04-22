package Game::HeroesVsAliens;

use 5.006;
use strict;
use warnings;
our $VERSION = '1.01';

use Moo;

use Game::HeroesVsAliens::Mouse;
use Game::HeroesVsAliens::Cell;
use Game::HeroesVsAliens::Hero::Blue;
use Game::HeroesVsAliens::Hero::Pink;
use Game::HeroesVsAliens::Alien::One;
use Game::HeroesVsAliens::Alien::Two;
use Game::HeroesVsAliens::Alien::Three;
use Game::HeroesVsAliens::Alien::Four;
use Game::HeroesVsAliens::Message;
use Game::HeroesVsAliens::Bonus;

use SDL::Event;
use SDLx::App;
use SDL::GFX::Primitives;
use SDLx::Text;
use SDL::GFX::Primitives;
use SDLx::Sound;
use Data::LnArray;

with 'Game::HeroesVsAliens::Role::ResourceDirectory';

has game_over => (
	is => 'rw',
	default => sub { 0 }
);

has game_grid => (
	is => 'rw',
	default => sub { Data::LnArray->new; }
);

has heroes => (
	is => 'rw',
	default => sub { Data::LnArray->new; }
);

has hero_upgrades => (
	is => 'rw',
	default => sub {
		{
			1 => 'Game::HeroesVsAliens::Hero::Blue',
			2 => 'Game::HeroesVsAliens::Hero::Pink'
		}
	}
);

has hero_cost => (
	is => 'rw',
	default => sub { 100 }
);

has hero_upgrade_cost => (
	is => 'rw',
	default => sub { 100 }
);

has aliens => (
	is => 'rw',
	default => sub { Data::LnArray->new; }
);

has alien_positions => (
	is => 'rw',
	default => sub { Data::LnArray->new; }
);

has aliens_interval => (
	is => 'rw',
	default => sub { 400 }
);

has messages => (
	is => 'rw',
	default => sub { Data::LnArray->new; }
);

has bonuses => (
	is => 'rw',
	default => sub { Data::LnArray->new; }
);


has frame => (
	is => 'rw',
	default => sub { 0 }
);

has cell_size => (
	is => 'rw',
	default => sub { 100 }
);

has cell_gap => (
	is => 'rw',
	default => sub { 3 }
);

has app_width => (
	is => 'rw',
	default => sub { 800 }
);

has app_height => (
	is => 'rw',
	default => sub { 600 }
);

has score => (
	is => 'rw',
	default => sub { 0 }
);

has stages => (
	is => 'rw',
	default => sub {
		{
			1 => 'Game::HeroesVsAliens::Alien::One',
			2 => 'Game::HeroesVsAliens::Alien::Two',
			3 => 'Game::HeroesVsAliens::Alien::Three',
			4 => 'Game::HeroesVsAliens::Alien::Four',
		} 
	}
);

has stage => (
	is => 'rw',
	default => sub { 1 }
);

has stage_winning_score => (
	is => 'rw',
	default => sub { 500 }
);

has stage_score => (
	is => 'rw',
	default => sub { 500 }
);

has score_text => (
	is => 'rw',
	default => sub {
		my $score = SDLx::Text->new(
			size => 18,
			x => 10,
			y => 10
		);
		return $score;
	}
);

has resources => (
	is => 'rw',
	default => sub { 1000 }
);

has resource_text => (
	is => 'rw',
	default => sub {
		my $resource = SDLx::Text->new(
			size => 18,
			x => 10,
			y => 30
		);
		return $resource;
	}
);

has ctx => (
	is => 'rw'
);

has background => (
	is => 'rw',
	default => sub {
		my $sprite = SDLx::Sprite->new(
			image => $_[0]->resource_directory . "/" . 'resources/game-background.png',
		);
		$sprite->rect->x(0);
		$sprite->rect->y(0);
		return $sprite;
	}
);

has mouse => (
	is => 'rw',
	default => sub {
		return Game::HeroesVsAliens::Mouse->new();
	}
);

sub run {
	my ($self) = @_;

	$self->ctx(
		SDLx::App->new(
			title => 'Heroes Vs Aliens',
			width => $self->app_width,
			height => $self->app_height,
		)
	);

	$self->ctx->add_event_handler(sub {
		my $e = shift;
		if ($e->type == SDL_MOUSEMOTION) {
			$self->mouse->x($e->motion_x);
			$self->mouse->y($e->motion_y);
		}
		if ($e->type == SDL_MOUSEBUTTONDOWN) {
			$self->add_hero();
		}
		$self->ctx->stop if ($e->type == SDL_QUIT);
	});

	$self->ctx->add_show_handler(sub {
		my $e = shift;
		if (!$self->game_over) {
			$self->background->draw($self->ctx);
			$self->show_grid();
			$self->handle_aliens();
			$self->handle_heroes();
			$self->handle_messages();
			$self->handle_bonuses();
			$self->handle_game_status();
			$self->frame($self->frame + 1);
			$self->ctx->update;
		}
	});

	$self->create_grid();

	my $snd = SDLx::Sound->new;
	$snd->play($self->resource_directory . 'resources/background.wav');

	$self->ctx->run();
}


sub create_grid {
	my ($self) = @_;
	for (my $y = $self->cell_size; $y < $self->app_height; $y += $self->cell_size) {
		for (my $x = 0; $x < $self->app_width; $x += $self->cell_size) {
			$self->game_grid->push(Game::HeroesVsAliens::Cell->new({
				x => $x,
				y => $y
			}));
		}
	}
}

sub show_grid {
	my ($self) = @_;
	for (@{$self->game_grid}) {
		$_->draw($self);
	}
}

sub handle_game_status {
	my $self = shift;
	$self->score_text->write_to($self->ctx, "Score: " . $self->score);
	$self->resource_text->write_to($self->ctx, "Resources: " . $self->resources);
	if ($self->game_over) {
		$self->draw_text(
			130,
			200,
			100,
			[255, 255, 255, 255],
			'Game Over'
		);
	}
	if ($self->score >= $self->stage_winning_score && $self->aliens->length == 0) {
		my $next_stage = $self->stage + 1;
		if ($self->stages->{$next_stage}) {
			$self->messages->push(Game::HeroesVsAliens::Message->new({
				value => 'You cleared stage ' . $self->stage,
				x => 130,
				y => 200,
				size => 50,
				color => [255, 255, 255],
			}));
			$self->stage_winning_score($self->score + $self->stage_score);	
			$self->stage($next_stage);
			$self->aliens_interval(400);
		} else {
			$self->draw_text(
				130,
				200,
				100,
				[255, 255, 255, 255],
				'Level Complete'
			);
			$self->draw_text(
				130,
				300,
				50,
				[255, 255, 255, 255],
				'You win with ' . $self->score . ' points'
			);
			$self->game_over(1);
		}
	}
}

sub upgrade_hero {
	my ($self, $i, $hero) = @_;

	my $next_level = $hero->level + 1;
	if ($self->hero_upgrades->{$next_level}) {
		if ($self->resources >= $self->hero_cost) {
			$self->heroes->splice($i, 1, $self->hero_upgrades->{$next_level}->new({
				level => $next_level,
				x => $hero->x,
				y => $hero->y,
				width => $hero->width,
				height => $hero->height,
			}));
			$self->resources( $self->resources - $self->hero_cost );
			$self->messages->push(Game::HeroesVsAliens::Message->new({
				value => 'Hero upgraded',
				x => $hero->x,
				y => $hero->y,
				size => 20,
				color => [0, 0, 0],
			}));
		} else {
			$self->messages->push(Game::HeroesVsAliens::Message->new({
				value => 'Not enough resources',
				x => $hero->x,
				y => $hero->y,
				size => 20,
				color => [0, 0, 0],
			}));
		}
	} else {
		$self->messages->push(Game::HeroesVsAliens::Message->new({
			value => 'Hero is fully upgraded',
			x => $hero->x,
			y => $hero->y,
			size => 20,
			color => [0, 0, 0],
		}));
	}
}


sub add_hero {
	my $self = shift;
	my $pos_x = $self->mouse->x - ($self->mouse->x % $self->cell_size) + $self->cell_gap;
	my $pos_y = $self->mouse->y - ($self->mouse->y % $self->cell_size) + $self->cell_gap;
	return if ($pos_y < $self->cell_size);
	for (my $i = 0; $i < $self->heroes->length; $i++) {
		my $hero = $self->heroes->[$i];
		if ($hero->x == $pos_x && $hero->y == $pos_y) {
			if ($hero->last_click_frame && $hero->last_click_frame - $self->frame < 100) {
				$self->upgrade_hero($i, $hero);	
			} else {
				$self->messages->push(Game::HeroesVsAliens::Message->new({
					value => 'click again to upgrade',
					x => $hero->x,
					y => $hero->y,
					size => 20,
					color => [0, 0, 0],
				}));
				$hero->last_click_frame($self->frame);
			}
			return;
		}
	}

	if ($self->resources >= $self->hero_cost) {
		$self->heroes->push($self->hero_upgrades->{1}->new(
			level => 1,
			x => $pos_x,
			y => $pos_y,
			width => $self->cell_size - $self->cell_gap * 2,
			height => $self->cell_size - $self->cell_gap * 2
		));
		$self->resources( $self->resources - $self->hero_cost );
	}
}

sub handle_heroes {
	my $self = shift;
	my $heroes = $self->heroes;
	for (my $i = 0; $i < scalar @{$heroes}; $i++) {
		$heroes->[$i]->draw($self);
		$heroes->[$i]->update($self);

		my $aliens = $self->aliens;
		if ($heroes->[$i]->health <= 0) {
			if ($heroes->[$i]->death_sprite->current_loop > 1) {
				for (my $j = 0; $j < scalar @{$aliens}; $j++) {
					if ($self->collision($heroes->[$i], $aliens->[$j])) {
						$aliens->[$j]->movement($aliens->[$j]->speed);
					}
				}
				$heroes->splice($i, 1);
				$i--;
			}
		} else {
			if ($self->alien_positions->indexOf($heroes->[$i]->y) != -1) {
				$heroes->[$i]->shooting(1);
			} else {
				$heroes->[$i]->shooting(0);
			}

			for (my $j = 0; $j < scalar @{$aliens}; $j++) {
				if ($heroes->[$i] && $self->collision($heroes->[$i], $aliens->[$j])) {
					$aliens->[$j]->movement(0);
					$heroes->[$i]->health($heroes->[$i]->health - 0.2);
				}
			}
		}
	}
}

sub handle_aliens {
	my $self = shift;
	my $aliens = $self->aliens;
	for (my $i = 0; $i < scalar @{$aliens}; $i++) {
		$aliens->[$i]->draw($self);
		$aliens->[$i]->update($self);
		if ($aliens->[$i]->x < 0) {
			$self->game_over(1);
		}
		if ($aliens->[$i]->dead) {
			if ($aliens->[$i]->death_sprite->current_loop > 1) {
				$aliens->splice($i, 1);
				$i--;
			}
		} elsif ($aliens->[$i]->health <= 0) {
			my $gained = $aliens->[$i]->max_health / 10;
			$self->messages->push(Game::HeroesVsAliens::Message->new({
				value => '+' . $gained,
				x => 100,
				y => 10,
				size => 20,
				color => [207, 176, 21],
			}));
			$self->messages->push(Game::HeroesVsAliens::Message->new({
				value => '+' . $gained,
				x => $aliens->[$i]->x,
				y => $aliens->[$i]->y,
				size => 20,
				color => [0, 0, 0],
			}));
			$self->resources(
				$self->resources + $gained
			);
			$self->score(
				$self->score + $gained
			);
			my $index = $self->alien_positions->indexOf($aliens->[$i]->y);
			$self->alien_positions->splice($index, 1);
			$aliens->[$i]->dead(1);
		}
	}
	if ($self->frame % $self->aliens_interval == 0 && $self->score < $self->stage_winning_score) {
		my $y_pos = int(rand(5) + 1) * $self->cell_size + $self->cell_gap;
		$self->aliens->push($self->stages->{int(rand($self->stage) + 1)}->new({
			y => $y_pos,
			x => $self->app_width,
			width => $self->cell_size - $self->cell_gap * 2,
			height => $self->cell_size - $self->cell_gap * 2
		}));
		$self->alien_positions->push($y_pos);
		if ($self->aliens_interval > 10) {
			my $interval = $self->aliens_interval - int(rand(40));
			$self->aliens_interval($interval > 10 ? $interval : 10);
		}
	}
}

sub handle_messages {
	my ($self) = @_;
	my $messages = $self->messages;
	for (my $i = 0; $i < $messages->length; $i++) {
		$messages->[$i]->update($self);
		$messages->[$i]->draw($self);
		if ($messages->[$i]->life_span >= 50) {
			$messages->splice($i, 1);
			$i--;
		}
	}
}

sub handle_bonuses {
	my ($self) = @_;

	if ($self->frame % 500 == 0 && $self->score < $self->stage_winning_score) {
		my $y_pos = int(rand(5) + 1) * $self->cell_size + $self->cell_gap;
		my $x_pos = int(rand(8)) * $self->cell_size + $self->cell_gap;
		$self->bonuses->push(Game::HeroesVsAliens::Bonus->new({
			x => $x_pos,
			y => $y_pos
		}));
	}

	my $bonuses = $self->bonuses;
	for (my $i = 0; $i < $bonuses->length; $i++) {
		$bonuses->[$i]->draw($self);
		if ($bonuses->[$i] && $self->collision($self->mouse, $bonuses->[$i])) {
			my $gained = $bonuses->[$i]->amount;
			
			$self->resources($self->resources + $gained);
			$self->messages->push(Game::HeroesVsAliens::Message->new({
				value => '+' . $gained,
				x => $bonuses->[$i]->x,
				y => $bonuses->[$i]->y,
				size => 20,
				color => [0, 0, 0]
			}));
			$self->messages->push(Game::HeroesVsAliens::Message->new({
				value => '+' . $gained,
				x => 130,
				y => 30,
				size => 20,
				color => [207, 176, 21]
			}));
			$bonuses->splice($i, 1);
			$i--;
		}
	}




}

sub collision {
	my ($self, $first, $second) = @_;
	if (
		!(
			$first->x > $second->x + $second->width ||
			$first->x + $first->width < $second->x ||
			$first->y > $second->y + $second->width ||
			$first->y + $first->height < $second->y
		)
	) {
		return 1;
	}
	return 0;
}

sub draw_rect {
	my ($self, $x, $y, $w, $h, $colour) = @_;
        my $rect = $self->ctx->draw_rect([$x, $y, $w, $h], $colour );
	$self->ctx->update;
}

sub draw_outline_rect {
	my ($self, $x, $y, $w, $h, $r, $g, $b, $a) = @_;
	SDL::GFX::Primitives::rectangle_RGBA(
		$self->ctx,
		$x,
		$y,
		$x + $w,
		$y + $h,
		$r,
		$g,
		$b,
		$a
	);
}

sub draw_text {
	my ($self, $x, $y, $size, $color, $text) = @_;
	my $draw = SDLx::Text->new(
		size => $size,
		x => $x,
		y => $y,
		color => $color
	);
	$draw->write_to($self->ctx, $text);
}

sub draw_arc {
	my ($self, $x, $y, $w, $h, $color) = @_;
	SDL::GFX::Primitives::arc_RGBA(
		$self->ctx,
		$x,
		$y,
		$w,
		-90,
		90,
		@{$color}
	);
}

sub draw_circle {
	my ($self, $x, $y, $w, $h, $color) = @_;
	SDL::GFX::Primitives::filled_circle_RGBA(
		$self->ctx,
		$x,
		$y,
		$w,
		@{$color}
	);
}

1;

__END__

=head1 NAME

Game::HeroesVsAliens - A tower defense game.

=head1 VERSION

Version 1.01

=cut

=head1 SYNOPSIS

	SDLPerl /bin/HeroesVsAliens.pl

=head1 Description

Game::HeroesVsAliens is a simple tower defense game using SDL. 

=head1 AUTHOR

lnation, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-heroesvsaliens at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-HeroesVsAliens>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::HeroesVsAliens

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-HeroesVsAliens>

=item * Search CPAN

L<https://metacpan.org/release/Game-HeroesVsAliens>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021->2025 by lnation.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut
