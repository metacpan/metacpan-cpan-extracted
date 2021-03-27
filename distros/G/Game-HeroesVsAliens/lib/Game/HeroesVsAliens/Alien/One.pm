package Game::HeroesVsAliens::Alien::One;

use Moo;

with 'Game::HeroesVsAliens::Role::Alien';

has health => (
	is => 'rw',
	default => sub { 100 }
);

has max_health => (
	is => 'rw',
	default => sub { 100 }
);

has walking_sprite => (
	is => 'rw',
	default => sub {
                my $sprite = SDLx::Sprite::Animated->new(
                        image => $_[0]->resource_directory . 'resources/alien1-walk.png',
                        width => 100,
                        height => 100
                );
                return $sprite;
	}
);

has attacking_sprite => (
	is => 'rw',
	default => sub {
                my $sprite = SDLx::Sprite::Animated->new(
                        image => $_[0]->resource_directory . 'resources/alien1-attack.png',
                        width => 100,
                        height => 100
                );
                return $sprite;
	}
);

has death_sprite => (
	is => 'rw',
	default => sub {
                my $sprite = SDLx::Sprite::Animated->new(
                        image => $_[0]->resource_directory . 'resources/alien1-death.png',
                        width => 100,
                        height => 100
                );
                return $sprite;
	}
);

1;
