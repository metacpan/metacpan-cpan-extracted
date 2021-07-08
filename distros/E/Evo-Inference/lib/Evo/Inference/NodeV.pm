package Evo::Inference::NodeV;

sub new {
	my ($class) = @_;

	my $self = {
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub set {
	my ($self, $node) = @_;

	$node->set($self);
}

sub feature {
	my ($self, $node) = @_;

	return $node->feature($self);
}

1;
