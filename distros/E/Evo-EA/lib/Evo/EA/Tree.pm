package Evo::EA::Tree;

sub new {
	my ($class) = @_;

	my $self = { root => TreeNode->new( () ), };

	$class = ref($class) || $class;

	bless $self, $class;
}

1;
