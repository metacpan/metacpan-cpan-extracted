package Game::HeroesVsAliens::Hero::Blue;

use Moo;

with 'Game::HeroesVsAliens::Role::Hero';

use Game::HeroesVsAliens::Projectile::Blue;

has health => (
	is => 'rw',
	default => sub { 100 }
);

has death_sprite => (
	is => 'rw',
	default => sub {
                my $sprite = SDLx::Sprite::Animated->new(
                        image => $_[0]->resource_directory . 'resources/boy-hero-death.png',
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
			image => $_[0]->resource_directory . 'resources/boy-hero-idle.png',
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
			image => $_[0]->resource_directory . 'resources/boy-hero-shooting.png',
			width => 100,
			height => 100,
		);
	}
);

sub add_projectile {
	my ($self, $app) = @_;
	$self->projectiles->push(Game::HeroesVsAliens::Projectile::Blue->new({
		x => $self->x + 70,
		y => $self->y + 15,
	}));
}

1;
