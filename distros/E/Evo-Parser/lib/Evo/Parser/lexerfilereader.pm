### file opener/reader for loading the lexer table (e.g. ga.l)

### files are mostly lines of the form:
### line : "LEXNAME doable" 

sub new {
	my ($class, $filename) = @_;

	$self = { table => {}, filename => $filename, };

	bless $self, $class;
}

sub load_lextable_file {
	my ($self) = @_;

	open (my $FH, $self->{filename});

	while (<$FH>) {

		### in file (a line), lines of "LEXTOKEN doable"
		### where doable is a functionality
		my @tokens = split(" ", $_);

		### skip '#' beginning lines, see below
		if (@tokens[0][0] == "#") {
			next;
		}

		### this automatically skips third '#' beginning comments
		$self->{table}[@tokens[0]] = @tokens[1];

	}	
	close $FH;

	return $self->{table};
}

sub is_valid_table {
	my $self = shift;

	### FIXME check if there are keywords in the table
	return 1;
}

1;	
