### a genetype's system's variable (mostly strings from the system)

sub new {
	my $class = shift;

	$self = { installer => genetypesystemvarinstaller->new($self), varString => undef, };

	bless $self, $class;
}

### make an adapter out of this class
sub getAdapter {
	my $self = shift;

	return genetypesystemvaradapter->new(installer->getobj);
}

sub getVarString {
	my $self = shift; 

	if ( defined($self->{varString}) ) { return $self->{varString}; }
					else { return undef; }
}

sub setVarString {
	my ($self, $s) = @_;

	$self->{varString} = $s;
}

1;

1;	
