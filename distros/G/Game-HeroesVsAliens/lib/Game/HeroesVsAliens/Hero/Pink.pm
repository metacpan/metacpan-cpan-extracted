package Game::HeroesVsAliens::Hero::Pink;

use Moo;

with 'Game::HeroesVsAliens::Role::Hero';

use Game::HeroesVsAliens::Projectile::Pink;

has health => (
	is => 'rw',
	default => sub { 200 }
);

has death_sprite => (
	is => 'rw',
	default => sub {
                my $sprite = SDLx::Sprite::Animated->new(
                        image => $_[0]->resource_directory . 'resources/girl-hero-death.png',
                        width => 100,
                        height => 100
                );
                return $sprite;
	}
);


has idle_sprite => (
	is => 'rw',
	default => sub {
		my $sprite = SDLx::Sprite::Animated->new( 
			image => $_[0]->resource_directory . 'resources/girl-hero-idle.png',
			width => 100,
			height => 100,
			type => 'reverse'
		);
		return $sprite;	
	}
);

has shooting_sprite => (
	is => 'rw',
	default => sub {
		my $sprite = SDLx::Sprite::Animated->new(
			image => $_[0]->resource_directory . 'resources/girl-hero-shooting.png',
			width => 100,
			height => 100,
		);
	}
);

sub add_projectile {
	my ($self, $app) = @_;
	$self->projectiles->push(Game::HeroesVsAliens::Projectile::Pink->new({
		x => $self->x + 70,
		y => $self->y + 15,
	}));
}

1;
