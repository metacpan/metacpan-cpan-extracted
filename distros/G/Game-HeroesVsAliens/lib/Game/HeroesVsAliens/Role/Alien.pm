package Game::HeroesVsAliens::Role::Alien;

use Moo::Role;

with 'Game::HeroesVsAliens::Role::ResourceDirectory';

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

has speed => (
	is => 'rw',
	default => sub {  
		rand(50) * 0.2 + 0.4;
	}
);

has movement => (
	is => 'rw',
	default => sub {  
		rand(50) * 0.2 + 0.4;
	}
);

has dead => (
	is => 'rw',
	default => sub { 0 }
);


sub draw {
	my ($self, $app) = @_;
	if ($self->dead) {
		$self->death_sprite->rect->x($self->x);
		$self->death_sprite->rect->y($self->y);
		if ($app->frame % 3 == 0) {
			$self->death_sprite->next;
		}
		$self->death_sprite->draw($app->ctx);
	} elsif  (!$self->movement) {
		$self->attacking_sprite->rect->x($self->x);
		$self->attacking_sprite->rect->y($self->y);
		if ($app->frame % 3 == 0) {
			$self->attacking_sprite->next;
		}
		$self->attacking_sprite->draw($app->ctx);
	} else {
		$self->walking_sprite->rect->x($self->x);
		$self->walking_sprite->rect->y($self->y);
		if ($app->frame % 3 == 0) {
			$self->walking_sprite->next;
		}
		$self->walking_sprite->draw($app->ctx);
	}
	$app->draw_text($self->x + 15, $self->y + 15, 18, [255, 255, 255, 255], int($self->health))
}

sub update {
	my ($self, $app) = @_;
	$self->x($self->x - $self->movement);
}

1;
