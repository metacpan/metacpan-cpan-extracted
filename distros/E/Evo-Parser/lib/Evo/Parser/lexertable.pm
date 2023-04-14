### lexer of a NK fitness model, etc 

sub new {
	my ($class, $table) = @_;

	### table is a hash, constructed in lexer.pm
	$self = { table => $table, };

	bless $self, $class;
}

sub match_keyword_in_table {
	my ($self, $key) = @_;

	my $value_in_table =  $self->{table}[$key];

	if ( defined($value_in_table) ) { return $value_in_table } 
					else { return undef; }

	### never reached
}

sub get_table_hash {
	my $self = shift;

	return $self->{table};
}

1;	
