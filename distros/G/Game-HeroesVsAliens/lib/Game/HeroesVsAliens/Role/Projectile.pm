package Game::HeroesVsAliens::Role::Projectile;

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
	default => sub { 32 }
);

has height => (
	is => 'rw',
	default => sub { 32 }
);

has speed => (
	is => 'rw',
	default => sub { 5 }
);

has collision => (
	is => 'rw',
	default => sub { 0 }
);

sub draw {
	my ($self, $app) = @_;

	if ($self->collision) {
		$self->explode_sprite->rect->x($self->x);
		$self->explode_sprite->rect->y($self->y);
		if ($app->frame % 3 == 0) {
			$self->explode_sprite->next;
		}
		$self->explode_sprite->draw($app->ctx);
	} else {
		$self->sprite->rect->x($self->x);
		$self->sprite->rect->y($self->y);
		if ($app->frame % 3 == 0) {
			$self->sprite->next;
		}
		$self->sprite->draw($app->ctx);
	}
#	$app->draw_circle($self->x, $self->y, $self->width, $self->height, [200, 100, 200, 255]);
}

sub update {
	my ($self, $app) = @_;
	$self->x($self->x + $self->speed);
}


1;
