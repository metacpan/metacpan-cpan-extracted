package GFX::Enhancer::Energy;

### for use in tuples with pixel colour

sub new {
	my ($class, $e) = @_;

	my $self = { energy => $e, };

	$class = ref($class) || $class;

	bless $self, $class;
}


sub get_energy {
	my ($self) = @_;

	return $self->{energy}
}

sub set_energy {
	my ($self, $e) = @_;

	$self->{energy} = $e;
}

1;
