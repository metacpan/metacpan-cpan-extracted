package Evo::EA::GraphNode;

sub new {
	my ($class, $data) = @_;

	my $self = { data => $data or (), ### edge id/information
		connections => (), }; 

	$class = ref($class) || $class;

	bless $self, $class;
}

sub set_data {
	my ($self, $d) = @_;

	$self->{data} = $d;
}

sub add_connection {
	my ($self, $gn) = @_;

	push(@{$self->{connections}}, $gn);
}

1;
