package Evo::EA::TreeNode;

### dispatched into API Node visitor

sub new {
	my ($class, $data) = @_;

	my $self = { data => $data or (), ### edge id/information
		children => (), }; 

	$class = ref($class) || $class;

	bless $self, $class;
}

sub set_data {
	my ($self, $d) = @_;

	$self->{data} = $d;
}

sub add_child {
	my ($self, $tn) = @_;

	push(@{$self->{children}}, $tn);
}

1;
