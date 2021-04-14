package Lagrange::BoltzmannDiracLagrangian;

use parent 'Lagrange::Lagrangian';

sub new {
	my ($class, $name) = @_;
        my $self = $class->SUPER::new;

}

### d/dt (dL/dr)
sub leftphrase {
	my ($self, $dL, $dr_i) = @_;

	### approximation
	my $ddt = ExpDerivative->new()->d($dL,1);

	return $ddt;  
}		

### dL/dr + Sigma{lambdaii * dfi/dr)
sub rightphrase {
	my ($self, $dL, $dri, @lambdas, @dfi) = @_;

	### approximation
	my $potentialpart1 = ExpDerivative->new()->($dL,1);
	my $potentialpart2 = 0.0;

	for (my $i = 0; $i < length(@lambdas); $i++) {
		$potentialpart2 += @lambdas[$i] * @dfi[$i];
	}

	return $potentialpart1 + potentialpart2; 
}

### returns Lagrange multipliers
### these are calculated from the difference between the Boltzmann and 
### the Delta Dirac Function 
### This difference should be 0 to calculate the L multipliers
### The constraint is left out (more or less) 
sub gradientx {
	my ($self, $a, $x, $m, $T, $v) = @_;

	### The exponent of the Boltzmann function - Dirac Delta function
	### which is the to be optimized function, also
	### L(x) = b*exp(x) + lambda * g
	###( pow( sqrt($m / (2 * $self->{PI} * $self->{k} * $T)), 3) *
	###		exp ( - $m*$v*$v / (2 * $k * $T))) -
	###(1 / ( $a * sqrt($self->{PI}) ) * exp(- ($x/$a) * ($x/$a)));

	my $Boltzmann = Boltzmann->new;
	my $DiracFunc = DiracFunc->new;

	### in one dimension
	my $gradBoltzmannx = ExpDerivative->new()->d(0,
			(- $m*$v*$v / (2 * $Boltzmann->{k} * $T)));
	my $gradDiracx = ExpDerivative->new()->d(0,
			(- ($x/$a) * ($x/$a)));

	my @lambdas;

	### add the constant factors
	push(@lambdas, 
		pow( sqrt($m / (2 * $Boltzmann->{PI} * $Boltzmann->{k} * $T)), 3) * $gradBoltzmannx 
		- (1 / ( $a * sqrt($self->{PI}) ) * $gradDiracx));

	return @lambdas;
 
}

### returns Lagrange multipliers
### these are random as the gradient holds for b * exp(x) = 0
sub gradientx0 {
	my ($self) = @_;

	### in one dimension
	my $gradx = ExpDerivative->new()->d(0,0);
	my @lambdas;

	push(@lambdas, rand);

	return @lambdas;
 
}

1;
