package Evo::Inference::Node;

sub new {
	my ($class) = @_;

	my $self = {
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub set {
	my ($self, $v) = @_;

	$v->set($self);
}

sub feature {
	my ($self, $v) = @_;

	return $v->feature($self);
}

1;
