package Evo::Inference::RuleGrammar;

sub new {
	my ($class) = @_;

	my $self = {
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

1;
