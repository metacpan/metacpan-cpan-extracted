package Game::HeroesVsAliens::Bonus;

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
	default => sub { 100 }
);

has height => (
	is => 'rw',
	default => sub { 100 }
);

has amounts => (
	is => 'rw',
	lazy => 1,
	default => sub { [20, 30, 40, 50, 60] }
);

has amount => (
	is => 'rw',
	default => sub {
		my $amounts = $_[0]->amounts;
		return $amounts->[int(rand(scalar @{$amounts}))];
	}
);

has sprite => (
	is => 'rw',
	default => sub {
		my $sprite = SDLx::Sprite::Animated->new(
                        image => $_[0]->resource_directory . 'resources/bonus.png',
                        width => 50,
                        height => 50,
                );
	}
);

sub draw {
	my ($self, $app) = @_;

	$self->sprite->rect->x($self->x + 25);
	$self->sprite->rect->y($self->y + 20);
	if ($app->frame % 3 == 0) {
		$self->sprite->next;
	}
	$self->sprite->draw($app->ctx);
	$app->draw_text(
		$self->x + 15,
		$self->y + 15,
		18,
		[255, 255, 255, 2555],
		int($self->amount)
	);
}


1;
