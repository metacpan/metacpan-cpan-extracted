### A gene's type constructor, aggr 

sub new {
	my $class = shift;

	$self = { };

	bless $self, $class;
}

sub init {
	my ($self, $genetype) = @_;

	### FIXME

}

1;	
