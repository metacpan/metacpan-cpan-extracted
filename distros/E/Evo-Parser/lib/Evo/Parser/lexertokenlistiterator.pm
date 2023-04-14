### a list of token objects' iterator

sub new {
	my ($class, @list) = @_;

	$self = { list => @list, };

	bless $self, $class;
}

sub has_next {
	my $self = shift;

	if length($self->{list} > 0) {
		return 1;
	} else {
		return 0;
	}
}

sub next {
	my $self = shift;

###	if (length($self->{list}) < = 0)) {
###		return undef;
###	}

	my $return = $self->{list}[0];

	pop($self->{list});

	return $return;
}

1;	
