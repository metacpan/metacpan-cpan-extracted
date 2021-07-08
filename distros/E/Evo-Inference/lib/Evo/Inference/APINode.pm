package Evo::Inference::APINode;

use parent 'Node';

sub new {
	my ($class, $typenode) = @_;

	my $self = {
		typenode => $typenode,
	};

        my $self = $class->SUPER::new;
}

1;
