package Evo::GA::GenomeBase;

sub new {
	my ($class) = @_;

	my $self = { genes => (), };

	$class = ref($class) || $class;

	bless $self, $class;
}

sub mutate_simple {
	my ($self, $idx) = @_;

	$self->{genes}[$idx] = - $self->{genes}[$idx];
}

sub crossover_simple {
	my ($self, $idx1, $idx2, $genome) = @_;

	for (my $i = $idx1; $i < $idx2; $i++) {
		$self->{genes}[$i] = $genome->{genes}[$i] + $self->{genes}[$i]; ### FIXME
	}
}

sub add_to {
	my ($self, $gene) = @_;

	push (@{$self->{genes}}, $gene);
}

### estimate fitness function
sub fitness_simple {
	my ($self) = @_;
	my $sum = 0.0;

	for (my $i = 0; $i < scalar $self->{genes}; $i++) {
		$sum += $self->{genes}[$i];
	}

	return ($sum / scalar $self->{genes});	
}

sub norm {
	my ($self) = @_;

	my $dotp = 0.0;

	for (my $i = 0; $i < scalar $self->{genes}; $i++) {
		$dotp += $self->{genes}[$i] * $self->{genes}[$i];
	}
	
	return $dotp;
}

1;
