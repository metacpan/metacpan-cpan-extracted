package Evo::Inference::Index;

sub new {
	my ($class) = @_;

	my $self = {
		index => ' ',
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub get {
	my ($self) = @_;

	return $self->{index};
}

sub set {
	my ($self, $idx) = @_;

	$self->{index} = $idx;
}

1;
