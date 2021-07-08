package Evo::Inference::PostCondition;

sub new {
	my ($class, $clause) = @_;

	my $self = { clause => $clause,
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub solve {
	my ($self, @postvars) = @_;


}

1;
