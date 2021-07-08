package Evo::GA::MetaFunction;

sub new {
	my ($class, $func) = @_;

        my $self = { function => &$func, };
}

sub do {
	my ($self, $genome, @args) = @_;

	### &$self->{function}($genome)
	return $self->{function}->($genome, @args);
}


### several example meta bit functions (should normally be called before 
### mutation and cross-over)

### if bit is 1, mutate it
sub metabit1($genome, @args) {

	for (my $i = 0; $i < scalar @args; $i++) {
		if (@args[$i] == 1) {
			$genome->mutate_simple($i);
		}
	}

	return $genome;
}

1;
