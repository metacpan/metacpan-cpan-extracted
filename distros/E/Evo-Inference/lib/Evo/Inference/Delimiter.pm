package Evo::Inference::Delimiter;

sub new {
	my ($class) = @_;

	my $self = {
		del => ' ',
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub get {
	my ($self) = @_;

	return $self->{del};
}

sub set {
	my ($self, $d) = @_;

	$self->{del} = $d;
}

1;
