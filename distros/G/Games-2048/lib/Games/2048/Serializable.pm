package Games::2048::Serializable;
use 5.012;
use Moo::Role;

# increment this whenever we break compat with older game objects
our $VERSION = '0.04';

use Storable;
use File::Spec::Functions;
use File::HomeDir;

has version => is => 'rw', default => __PACKAGE__->VERSION;

sub _game_file {
	my ($file) = @_;
	state $dir = eval {
		my $my_dist_method = "my_dist_" . ($^O eq "MSWin32" ? "data" : "config");
		File::HomeDir->$my_dist_method("Games-2048", {create => 1});
	};
	return if !defined $dir;
	return catfile $dir, $file;
}

sub save {
	my ($self, $file) = @_;
	$self->version(__PACKAGE__->VERSION);
	eval { store $self, _game_file($file); 1 };
}

sub restore {
	my ($self, $file) = @_;
	$self = eval { retrieve _game_file($file) };
	$self;
}

sub is_valid {
	my $self = shift;
	defined $self->version and $self->version >= __PACKAGE__->VERSION;
}

1;
