package Games::2048::Game::Input;
use 5.012;
use Moo;

extends 'Games::2048::Game';

sub handle_input {
	my ($self, $app) = @_;

	while (defined(my $key = Games::2048::Util::read_key)) {
		   $self->handle_input_key_vector($app, $key)
		or $self->handle_input_key_quit_restart($app, $key)
		or $self->handle_input_key_option($app, $key)
		or $self->handle_input_key($app, $key);
	}
}

sub handle_input_key_vector {
	my ($self, $app, $key) = @_;
	my $vec = Games::2048::Util::key_vector($key);
	if ($vec) {
		$self->move($vec);
		1;
	}
}
sub handle_input_key_quit_restart {
	my ($self, $app, $key) = @_;
	if ($key =~ /^[q]$/i) {
		$app->quit(1);
		1;
	}
	elsif ($key =~ /^[r]$/i) {
		$app->restart(1);
		1;
	}
}
sub handle_input_key_option {
	my ($self, $app, $key) = @_;
	if ($key =~ /^[a]$/i) {
		$self->no_animations(!$self->no_animations);
		1;
	}
	elsif ($key =~ /^[-_]$/) {
		$self->zoom($self->zoom - 1);
		1;
	}
	elsif ($key =~ /^[=+]$/) {
		$self->zoom($self->zoom + 1);
		1;
	}
	elsif ($key =~ /^[c]$/i) {
		$self->colors($self->colors + 1);
		1;
	}
}
sub handle_input_key {}

sub handle_finish {
	my ($self, $app) = @_;

	while (1) {
		my $key = Games::2048::Util::poll_key;
		$self->handle_finish_key($app, $key) and return;
	}
}

sub handle_finish_key {
	my ($self, $app, $key) = @_;
	if ($key =~ /^[nq]$/i) {
		$app->quit(1);
		1;
	}
	elsif ($key =~ /^[yr\n]$/i) {
		1;
	}
}

1;
