package Evo::Inference::Flyweight;

sub new {
	my ($class) = @_;

	my $self = {
		x => undef,
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub get {
	my ($self) = @_;

	return $self->{x};
}

sub set {
	my ($self, $x) = @_;

	$self->{x} = $x;
}

1;
