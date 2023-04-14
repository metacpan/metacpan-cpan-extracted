### The lexer init of this EC/numerical analysis system, the numerical system

use parent 'Evo::Parser::lexer'

sub new {
	my $class = shift;

	### subclass of the original Evo::Parser lexer.pm
	$self = $class->SUPER::new;

	### NOTE : this is the default init
	$self->{gasourcefilename} = "./maple.l";

	### the words (string) syntax scanned in
	$self->{scans} = undef;
}

### main API
sub lexscan {
	($self, $filename) = shift;
	
	$self->init($self->{gasourcefilename});
	$self->scan(undef, $filename); ### NOTE : the aggregatee is empty

	$self->{lexerscanner}->get_scans;
}

1;	
