package Lagrange::Lagrangian;

sub new {
	my ($class) = @_;
	my $self = {
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

### d/dt (dL/dr)
sub leftphrase {
	my ($self, ) = @_;

	### subclass responsibility
}		

### dL/dr + Sigma{lambdaii * dfi/dr)
sub rightphrase {
	my ($self) = @_;

	### subclass responsibility
}

1;
