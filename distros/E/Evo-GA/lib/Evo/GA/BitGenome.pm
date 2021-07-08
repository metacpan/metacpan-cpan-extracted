package Evo::GA::BitGenome;

### genome with 0 or 1 genes

use parent 'Evo::GA::GenomeBase';

sub new {
	my ($class) = @_;

        my $self = $class->SUPER::new;
}

sub mutate {
	my ($self, $idx) = @_;

	if ($self->{genes}[$idx] == 0) {
		$self->{genes}[$idx] = 1;
	} else {
		$self->{genes}[$idx] = 0;
	}	
}

sub crossover {
	my ($self, $idx1, $idx2, $genome) = @_;

	for (my $i = $idx1; $i < $idx2; $i++) {
		$self->{genes}[$i] = $genome->{genes}[$i] | $self->{genes}[$i]; 
	}
}

### complement of 2 genomes (xor)
sub genome_complement {
	my ($self, $inputgenome) = @_;
	
	my $returngenome = BitGenome->new; 

	for (my $i = 0; $i < scalar $self->{genes}; $i++) {
		$returngenome->add_to( 
			$inputgenome->{genes}[$i] ^ $self->{genes}[$i]);
	}

	return $returngenome;
}

1;
