package Game::HeroesVsAliens::Cell;

use Moo;

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

sub draw {
	my ($self, $app) = @_;
	if ($app->mouse->x && $app->mouse->y && $app->collision($self, $app->mouse)) {
		$app->draw_outline_rect($self->x, $self->y, $self->width, $self->height, 200, 200, 200, 255);
	}
}

1;
