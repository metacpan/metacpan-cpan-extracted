### a genetype's system's variable adapter 

sub new {
	my ($class, $sysvaradaptee) = @_;

	$self = { adaptee => $sysvaradaptee, };

	bless $self, $class;
}

sub getString {
	my $self = shift;

	if ( defined($self->{adaptee}->getVarString) ) {
		return $self->{adaptee}->getVarString; }
	else {
		return undef;
	}
}

1;	
