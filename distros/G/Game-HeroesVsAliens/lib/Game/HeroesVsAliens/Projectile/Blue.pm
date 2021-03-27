package Game::HeroesVsAliens::Projectile::Blue;

use Moo;

with 'Game::HeroesVsAliens::Role::Projectile';

has power => (
	is => 'rw',
	default => sub { 20 }
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

1;
