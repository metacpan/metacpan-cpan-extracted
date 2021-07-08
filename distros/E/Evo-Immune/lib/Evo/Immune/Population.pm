package Evo::Immune::Population;

use parent 'Evo::GA::Population';

sub new {
	my ($class) = @_;

	my $self = $class->SUPER::new;
}

sub fittest {
	my ($self, @args) = @_; ### args contains a genome
	my $fitness = 0.0;
	my $fittest_genome = undef;

	my $metafunction = Evo::Immune::MetaFunction->new(&fitness_M0);

	for (my $i = 0; $i < scalar $self->{population}; $i++) {
		my $f = $metafunction->do($self->{population}[$i], @args);

		if ($f > $fitness) {
			$fitness = $f;
			$fittest_genome = $self->{population}[$i];	

		}
	}

	return $fittest_genome;
}

1;
