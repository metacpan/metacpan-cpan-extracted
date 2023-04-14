### a genetype's system's variable (mostly strings from the system)
### NOTE : storation variable type

sub new {
	my ($class, $s) = @_;

	$self = { varString => $s, };

	bless $self, $class;
}

sub getVarString {
	my $self = shift; 

	if ( defined($self->{varString}) ) { return $self->{varString}; }
					else { return undef; }
}

1;	
