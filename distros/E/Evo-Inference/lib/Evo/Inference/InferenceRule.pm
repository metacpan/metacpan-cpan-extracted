package Evo::Inference::InferenceRule;

sub new {
	my ($class) = @_;

	my $self = { 
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

1;
