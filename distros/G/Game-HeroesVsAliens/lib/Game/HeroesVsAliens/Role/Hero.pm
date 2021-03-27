package Game::HeroesVsAliens::Role::Hero;

use Moo::Role;

with 'Game::HeroesVsAliens::Role::ResourceDirectory';

use Data::LnArray;
use SDLx::Sprite::Animated;

has level => (
	is => 'rw',
	required => 1
);

has x => (
	is => 'rw'
);

has y => (
	is => 'rw'
);

has width => (
	is => 'rw',
	default => sub { 100 }
);

has height => (
	is => 'rw',
	default => sub { 100 }
);

has shooting => (
	is => 'rw',
	default => sub { 0 }
);

has block_shot => (
	is => 'rw',
	default => sub { 0 }

);

has last_click_frame => (
	is => 'rw',
);

has projectiles => (
	is => 'rw',
	default => sub { Data::LnArray->new }
);

has timer => (
	is => 'rw',
	default => sub { 0 }
);

sub draw {
	my ($self, $app) = @_;
	if ($self->health <= 0) {
		$self->death_sprite->rect->x($self->x);
		$self->death_sprite->rect->y($self->y);
		if ($app->frame % 3 == 0) {	
			$self->block_shot(0);	
			$self->death_sprite->next;
		}
		$self->death_sprite->draw($app->ctx);
	} elsif ($self->shooting) {
		$self->shooting_sprite->rect->x($self->x);
		$self->shooting_sprite->rect->y($self->y);
		if ($app->frame % 3 == 0) {	
			$self->block_shot(0);	
			$self->shooting_sprite->next;
		}
		$self->shooting_sprite->draw($app->ctx);
	} else {
		$self->idle_sprite->rect->x($self->x);
		$self->idle_sprite->rect->y($self->y);
		if ($app->frame % 3 == 0) {
			$self->idle_sprite->next;
		}
		$self->idle_sprite->draw($app->ctx);
	}
	$app->draw_text($self->x + 15, $self->y + 15, 18, [255, 255, 255, 255], int($self->health))
}

sub update {
	my ($self, $app) = @_;
	if ($self->shooting && !$self->block_shot) {
		if ($self->shooting_sprite->current_frame == 1) {
			$self->add_projectile($app);
			$self->block_shot(1);
		}
	} else {
		$self->timer(0);
	}
	$self->handle_projectiles($app);
}

sub handle_projectiles {
	my ($self, $app) = @_;
	my $projectiles = $self->projectiles;
	for (my $i = 0; $i < scalar @{$projectiles}; $i++) {
		$projectiles->[$i]->update($app);
		$projectiles->[$i]->draw($app);
		if ($projectiles->[$i]->collision) {
			if ( $projectiles->[$i]->explode_sprite->current_loop > 1 ) {
				$projectiles->splice($i, 1);
				$i--;
			}
		} else {
			my $aliens = $app->aliens;
			for (my $j = 0; $j < scalar @{$aliens}; $j++) {
				if ($aliens->[$j] && $projectiles->[$i] && $app->collision($projectiles->[$i], $aliens->[$j])) {
					$aliens->[$j]->health($aliens->[$j]->health - $projectiles->[$i]->power);
					$projectiles->[$i]->collision(1);
				}
			}
		}

		if ($projectiles->[$i] && $projectiles->[$i]->x > $app->app_width - $app->cell_size) {
			$projectiles->splice($i, 1);
			$i--;
		}
	}
}

1;
