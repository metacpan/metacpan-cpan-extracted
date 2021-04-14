package Lagrange::ExpIntegral;

use parent 'Lagrange::Integral';

sub new {
	my ($class, $name) = @_;
        my $self = $class->SUPER::new;

}

### (exponential) integral of exp($pow * $x) with dx  
sub int {

	my ($self, $x, $pow) = @_;

	return (1 / $pow * exp($x)); 

}

1;
