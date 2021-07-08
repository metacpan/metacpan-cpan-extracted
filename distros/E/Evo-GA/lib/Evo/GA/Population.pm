package Evo::GA::Population;

sub new {
	my ($class) = @_;

	my $self = { population => (), ### genomes instances
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub add_to {
	my ($self, $genome) = @_;

	push (@{$self->{population}}, $genome);
}

sub fittest_simple {
	my ($self) = @_;
	my $fittest_genome = undef;
	my $fitness = 0.0;

	for (my $i = 0; $i < scalar $self->{population}; $i++) {
		my $f = $self->{population}[$i]->fitness_simple;
		if ($f >= $fitness) {
			$fitness = $f;
			$fittest_genome = $self->{population}[$i];
		}	
	}

	return $fittest_genome;
}

### must be averaged over a grand population
sub epistasis_variance {
	my ($self, @genes) = @_;
	my $average_allele_value = 0.0;

	for (my $i = 0; $i < scalar @genes; $i++) {
		$average_allele_value += @genes[$i];
	}
	$average_allele_value /= scalar @genes;	
	
	return ($self->average_fitness - $average_allele_value) * ($self->average_fitness - $average_allele_value);
}
	

sub average_fitness {
	my ($self) = @_;
	my $sum = 0.0;

	for (my $i = 0; $i < scalar $self->{population}; $i++) {
		$sum += $self->{population}[$i]->fitness_simple;
	}

	return ($sum / scalar $self->{population});
}	
		
1;
