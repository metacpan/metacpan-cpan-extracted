### (String) Tokens in a list 
### can be used as a mixin for token lists

sub new {
	my $class = shift;

	$self = { tokens => (), };

	bless $self, $class;
}

sub add_token {
	my ($self, $token) = @_;

	push($token, $self->{tokens});
}

sub get_tokens_list {
	my ($self) = @_;

	return $self->{tokens};
}

sub set_list {
	my ($self, $l) = @_;

	$self->{tokens} = $l;
}


1;
