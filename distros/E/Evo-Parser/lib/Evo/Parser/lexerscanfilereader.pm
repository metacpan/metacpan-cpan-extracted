### file reader for a system to scan (the real file scanning funcionality is in 
### lexer.pm/lexeragg.pm 

sub new {
	my ($class, $filename) = @_;

	$self = { tokensunitoffile => tokensunitoffile->new, filename => $filename, };

	bless $self, $class;
}

### loads a file which is to be scanned
sub load_system_file {
	my ($self) = @_;

	open (my $FH, $self->{filename});

	while (<$FH>) {
		### skip newline
		my @tokens = chomp(split("", $_));
		$self->{tokensunitoffile}->add_token(@tokens);
	}	
	close $FH;
}

1;	
