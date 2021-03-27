package Game::HeroesVsAliens::Message;

use Moo;

has value => (
	is => 'rw',
);

has x => (
	is => 'rw',
);

has y => (
	is => 'rw'
);

has size => (
	is => 'rw'
);

has life_span => (
	is => 'rw',
	default => sub { 0 }
);

has color => (
	is => 'rw'
);

has opacity => (
	is => 'rw',
	default => sub { 1 } 
);

sub update {
	my ($self, $app) = @_;
	$self->y($self->y - 0.3);
	$self->life_span($self->life_span + 1);
	$self->opacity($self->opacity - 0.03) if ($self->opacity > 0.03);
}

sub draw {
	my ($self, $app) = @_;
	$app->draw_text(
		$self->x,
		$self->y,
		$self->size,
		[@{$self->color}, $self->opacity],
		$self->value
	);
}

1;
