use 5.38.0;
use experimental 'class';
our $VERSION = 0.08;

class Game::Snake::Tail :isa(Game::Snake::Head) {
	use Raylib::FFI;

	method draw () {
		my $sprite = $self->sprite;

		if ($self->last) {
			my $dir = $self->bend ? $self->bend : $self->direction;
			if ($dir eq 'left') {
				$sprite->y(192);
				$sprite->x(192);
			} elsif ($dir eq 'right') {
				$sprite->y(128);
				$sprite->x(256);
			} elsif ($dir eq 'up') {
				$sprite->y(128);
				$sprite->x(192);
			} else {
				$sprite->y(192);
				$sprite->x(256);
			}
		} elsif ($self->bend) {
			if ($self->direction eq 'left' && $self->bend eq 'down' or $self->direction eq 'up' && $self->bend eq 'right') {
				$sprite->y(0);
				$sprite->x(0);
			} elsif ($self->direction eq 'right' && $self->bend eq 'down' or $self->direction eq 'up' && $self->bend eq 'left') {
				$sprite->y(0);
				$sprite->x(128);
			} elsif ($self->direction eq 'left' && $self->bend eq 'up' or $self->direction eq 'down' && $self->bend eq 'right') {
				$sprite->y(64);
				$sprite->x(0);
			} else {
				$sprite->y(128);
				$sprite->x(128);
			}
		} else {
			if ($self->direction eq 'left' or $self->direction eq 'right') {
				$sprite->y(0);
				$sprite->x(64);
			} else {
				$sprite->y(64);
				$sprite->x(128);
			}
		}

		$sprite->draw($self->x, $self->y, $self->width, $self->height);
	}
}

1;

=pod

=cut
