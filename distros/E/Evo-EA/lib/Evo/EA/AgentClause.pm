package Evo::EA::AgentClause;

sub new {
	my ($class) = @_;

	my $self = { clause => undef, };

	$class = ref($class) || $class;

	bless $self, $class;
}

### derived should be returning the clause's system return
sub parse {
	my ($self) = @_;

	return $self->{clause};
};

1;
