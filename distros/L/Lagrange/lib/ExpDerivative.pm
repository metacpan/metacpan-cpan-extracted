package Lagrange::ExpDerivative;

use parent 'Lagrange::Derivative';

sub new {
	my ($class, $name) = @_;
        my $self = $class->SUPER::new;

}

### (exponential) derivative of exp($pow * $x) with dx  
sub d {

	my ($self, $x, $pow) = @_;

	return ($pow * exp($x)); 

}

1;
