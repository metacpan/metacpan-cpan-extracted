### A subclass for using an Attacking/DefendingFunctor with a 
### Metropolis-Hastings algorithm.

sub new {
	my ($class) = @_;

	$self = { lowerbound => 0.25, upperbound => 0.4 };

	bless $self, $class;
};

sub setLower {
	my ($self, $lb) = @_;

	$self->{lowerbound} = $lb;
}

sub setUpper {
	my ($self, $ub) = @_;

	$self->{upperbound} = $ub;
}

sub do {
	my ($self, $entity1, $entity2) = @_;

	if (my $random = 1 / rand >= $self->{lowerbound} or $random <= $self->{upperbound}) {

		return 1;
	} else {
		return 0;
	}
	
};
1;
