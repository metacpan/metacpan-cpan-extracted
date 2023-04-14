### lexer of a NK fitness model, etc 

sub new {
	my $class = shift;

	### contains the table of lex keywords (parser syntax e.g. in a ga.l file)
	$self = { table_object => undef, lexerscanner => undef, };

	bless $self, $class;
}

## API
### read in a ga.l file (for the lex keyword table)
sub init {

	my ($self, $filename) = @_;

	my $filereader = lexerfilereader->new($filename);	
	$self->init_with_table_object($filereader->load_lextable_file);

}

### API
### read in a file to scan for the lexer
sub scan {
	### NOTE : formally use the aggregatee lexeragg1 for matching keywords	
	my ($self, $lexeragg1, $filename) = @_;

	my $filescanreader = lexerscanfilereader->new($filename);
	### set the tokens initialization of the system 
	$self->{lexerscanner} = lexerscan->new->init_tokensunitoffile($filescanreader->load_system_file);
	### scan in the system file
	$self->{lexerscanner}->compute_scan($self->get_lexer_table);
}

### set the lex keyword table in this class
sub init_with_table_object {
	my ($self, %tablehash) = @_;

	$self->{table_object} = lexertable->new(%tablehash);
}

sub get_lexer_table {
	my $self = shift;

	return $self->{table_object};
}

1;
