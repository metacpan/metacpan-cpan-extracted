package Lagrange::ExpCosIntegral;

use parent 'Lagrange::Integral';

### (exponential) integral of exp($x * cos(theta)) with dtheta and
### boundaries 2 * PI and 0

sub new {
	my ($class, $name) = @_;
        my $self = $class->SUPER::new;

}

sub int {

	my ($self, $x, $theta) = @_;

	return (2 * 3.141528 * BesselF0->new()->funcall($theta));
}

1;
