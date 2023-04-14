### (String) Tokens in a list (of a whole scanned in file) 

sub new {
	my $class = shift;

	### contains the table of lex keywords (parser syntax e.g. in a ga.l file)
	$self = { tokens => (), };

	bless $self, $class;
}

sub add_token {
	my ($self, $token) = @_;

	push($token, $self->{tokens});
}

sub get_file_tokens_list {
	my ($self) = @_;

	return $self->{tokens};
}

sub set_list {
	my ($self, $l) = @_;

	$self->{tokens} = $l;
}


1;
