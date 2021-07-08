package Evo::Inference::APINodeV;

use parent 'NodeV';

sub new {
	my ($class) = @_;

	my $self = {
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

1;
