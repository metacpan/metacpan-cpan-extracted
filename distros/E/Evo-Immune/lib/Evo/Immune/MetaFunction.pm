package Evo::Immune::MetaFunction;

use parent 'Evo:::GA::MetaFunction';

sub new {
	my ($class, $func) = @_;

	my $self = $class->SUPER::new($func);
}

### (partial) fitness function, sum of differ between antigens and antibodies
sub fitness_M0 ($antibody_genome, @args) {
	my $sum = 0;
	my $antigen_genome = @args[0];

	my $genome = $antibody_genome->genome_complement($antigen_genome);

	return bitcount($genome->{genes});
}

### count all bits of 1 in a genome
sub bitcount(@l) {
	my $sum = 0;
	return grep { $_ and $sum++ } @_ and $sum;
}

1;
