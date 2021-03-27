package Game::HeroesVsAliens::Projectile::Pink;

use Moo;

with 'Game::HeroesVsAliens::Role::Projectile';

has power => (
	is => 'rw',
	default => sub { 40 }
);

has sprite => (
	is => 'rw',
	default => sub {
		my $sprite = SDLx::Sprite::Animated->new(
                        image => $_[0]->resource_directory . 'resources/girl-hero-projectile.png',
                        width => 32,
                        height => 32,
                );
	}
);

has explode_sprite => (
	is => 'rw',
	default => sub {
		my $sprite = SDLx::Sprite::Animated->new(
                        image => $_[0]->resource_directory . 'resources/girl-hero-explode-projectile.png',
                        width => 32,
                        height => 32,
                );
	}
);

1;
