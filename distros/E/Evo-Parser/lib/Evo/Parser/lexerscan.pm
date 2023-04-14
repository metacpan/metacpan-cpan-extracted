### some sort of mixin class for a scanned in file (as a system on its own) 
### contains a tokensunitoffile which is the object for manipulating the file
### (which was scanned in) and translates the tokensunitoffile to a lexerscans
### object for the parse tree later on

sub new {
	my $class = shift;

	$self = { tokensunitoffile => undef, scans => lexerscans->new, };

	bless $self, $class;
}

### init API
sub init_tokensunitoffile {
	my ($self, @tunit) = @_;

	$self->{tokensunitoffile} = @tunit;
}

### API
sub compute_scan {
	my ($self, $lexertable) = @_;

	if (not defined($lexertable) and not $lexertable->is_valid_table) {

		print "ERROR : Quasi no keywords, please load a file such as ga.l\n";
		exit;

	}

	### NOTE : dispatches the list of tokens
	$self->{scans}->scan($lexertable->get_table_hash, $self->{tokensunitoffile}->get_file_tokens_list);

### FIXME put somehwere else :	my $parser = parser->new->compute_parse($lexertable, $self->{scans});

	
}

sub get_scans {
	my $self = shift;

	return $self->scans;
}

1;	
