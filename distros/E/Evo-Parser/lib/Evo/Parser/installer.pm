### an object that cores its attributes into cores

sub new {
	my $class = shift;

	$self = { $agginstallerobj => undef, };

	bless $self, $class;
}

1;	
