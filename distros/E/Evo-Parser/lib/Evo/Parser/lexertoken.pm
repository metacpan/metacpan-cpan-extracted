### lexer of a NK fitness model, etc 

sub new {
	my ($class, $char) = @_;

	### table is a hash, constructed in lexer.pm
	$self = { token => $char, };

	bless $self, $class;
}

### the char itself
sub token {
	$self = shift;

	return $self->{token};
}

1;	
