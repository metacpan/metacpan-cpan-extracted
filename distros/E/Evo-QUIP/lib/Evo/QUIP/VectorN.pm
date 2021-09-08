package Evo::QUIP::VectorN;

sub new {
	my ($class, $n) = @_;

	my $self = { vector => (), };

	for (my $i = 0; $i < $n; $i++) {
		push(@{$self->{vector}}, 0);
	}

        $class = ref($class) || $class;
        bless $self, $class;	
}

1;
