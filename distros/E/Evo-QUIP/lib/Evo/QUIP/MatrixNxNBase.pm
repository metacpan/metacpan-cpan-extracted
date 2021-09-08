package Evo::QUIP::MatrixNxNBase;

sub new {
	my ($class, $nrows, $mcols) = @_;

	my $self = { rows => (), cols => (), };

	for (my $i = 0; $i < $nrows; $i++) {
		push($self->{rows}, ());
		for (my $j = 0; $j < $ncols; $j++) {
			push($self->{rows}[$i], 0);
		}
	}

        $class = ref($class) || $class;
        bless $self, $class;	
}

sub multiply_by_vector {
	my ($self, $v) = @_;

	### FIXME

}

1;
