package Evo::EA::Agent;

sub new {
	my ($class) = @_;

	my $self = {};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub update_with_agent {
	my ($self, $agent) = @_;

	$agent->update_once($self);
}

sub update_once {
	my ($self, $agent) = @_;

	$agent->interprete;
}

### do agent's main logic
sub interprete {
	my ($self) = @_;

}

1;
