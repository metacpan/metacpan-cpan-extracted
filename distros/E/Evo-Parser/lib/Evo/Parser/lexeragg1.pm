### lexer.pm aggregatee for matching keywords/scanwords

sub new {
	my $class = shift;

	$self = { tokens => undef, };

	bless $self, $class;
}

sub set_tokens {
	my ($self, @l) = @_;

	$self->{tokens} = @l;
}

### matches a lex table keyword in this class' table with another (key)word
sub match_keyword {
	### $keyword is a string in a lexer file (e.g. ga.l as in flex/lex)
	### $tablekeyword is a string in the lex symbols table
	my ($self, $keyword, $tablekeyword) = @_;

	my $keywordtokens = lexertokenlist->new;
	$keywordtokens->tokenize_word($keyword);	
	my $tablekeywordtokens = lexertokenlist->new;
	$tablekeywordtokens->tokenize_word($tablekeyword);	

	my $iter = lexertokenlistiterator->new($keywordtokens->{tokens});
	my $titer = lexertokenlistiterator->new($tablekeywordtokens->{tokens});

	if (length($keyword) < length($tablekeyword)) {
		return undef;
	}

	### match at shortest string
	while ($iter->has_next and $titer->has_next) {
		if ($iter->next == $titer->next) {
			next;
		} else {
			return undef;
		} 
	}

	return 1; ### match true
}

1;	

