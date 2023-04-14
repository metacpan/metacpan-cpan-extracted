### A gene's type, subclassed in multiple (gene) types 

sub new {
	my $class = shift;

	$self = { stored_system_variables => {}, };

	bless $self, $class;
}

sub init {
	my ($self, $agginitobj) = @_;

	$agginitobj->init($self);
}

1;	
