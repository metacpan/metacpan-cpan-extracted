package Evo::EA::Graph;

### dispatched into API Node visitor

sub new {
	my ($class) = @_;

	my $self = { node => GraphNode->new( () ), };

	$class = ref($class) || $class;

	bless $self, $class;
}

1;
