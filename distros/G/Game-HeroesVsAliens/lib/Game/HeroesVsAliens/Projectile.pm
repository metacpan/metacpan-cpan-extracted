package Game::HeroesVsAliens::Projectile;

use Moo;

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

has power => (
	is => 'rw',
	default => sub { 20 }
);

has speed => (
	is => 'rw',
	default => sub { 5 }
);

has sprite => (
	is => 'rw',
	default => sub {
		my $sprite = SDLx::Sprite::Animated->new(
                        image => $_[0]->resource_directory . 'resources/boy-hero-projectile.png',
                        width => 32,
                        height => 32,
                );
	}
);

has explode_sprite => (
	is => 'rw',
	default => sub {
		my $sprite = SDLx::Sprite::Animated->new(
                        image => $_[0]->resource_directory . 'resources/boy-hero-explode-projectile.png',
                        width => 32,
                        height => 32,
                );
	}
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
