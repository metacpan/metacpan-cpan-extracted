package Evo::Inference::Condition;

### inferred clause/condition

sub new {
	my ($class, $precondition, $postcondition) = @_;

	my $self = { precondition => $precondition,
			postcondition => $postcondition,
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub solve {
	my ($self, @prevars) = @_;
	my @conds;

	@conds = $self->{precondition}->solve(@prevars);
	return $self->{postcondition}->solve(@conds);
}

1;
