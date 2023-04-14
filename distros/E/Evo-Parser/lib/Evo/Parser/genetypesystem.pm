### a genetype's system, using a dispatcher (sometimes of strings)

sub new {
	my $class = shift;

	$self = { system_variables => {}, };

	bless $self, $class;
}

sub init {
	my ($self, $agginitobj) = @_;

	$agginitobj->init($self);
}

1;	
