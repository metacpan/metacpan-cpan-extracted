package Evo::Inference::AxiomGrammar;

sub new {
	my ($class) = @_;

	my $self = {
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

1;
