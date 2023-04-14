### a stupid coreder based on a subclass where $obj is its core
### (which you get with getobj method) 

use parent 'installer';

sub new {
	my ($class, $obj) = @_;

	$self = $class->SUPER::new;

	####$self->{agginstallerobj} = genetypesystemvar->new; 
	$self->{agginstallerobj} = $obj; 

	bless $self, $class;
}

sub getobj {
	my $self = shift;

	return $self->{obj};
}

1;	
