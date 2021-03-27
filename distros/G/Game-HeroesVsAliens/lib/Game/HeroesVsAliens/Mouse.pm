package Game::HeroesVsAliens::Mouse;

use Moo;

has x => (
	is => 'rw'
);

has y => (
	is => 'rw'
);

has width => (
	is => 'rw',
	default => sub { 0.1 }
);

has height => (
	is => 'rw',
	default => sub { 0.1 }
);

1;
