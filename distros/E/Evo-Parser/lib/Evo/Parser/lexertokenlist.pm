### a list of token objects

sub new {
	my ($class) = @_;

	### table is a hash, constructed in lexer.pm
	### tokens is a list of token objects
	$self = { tokens => (), };

	bless $self, $class;
}

sub add_token {
	my ($self, $char) = @_;

	push(@{$self->{tokens}}, token->new($char));
}


sub get_tokens {
	my ($self) = @_;

	return $self->{tokens};
}

sub tokenize_word {
	### $word is a string
	my ($self, $word) = @_;

	@chars = split("", $word);
	for (my $i = 0; $i < length(@chars); $i++) {

		$self->add_token(@char[$i]);

	}
	
}

1;	
