package Lagrange::BoltzmannDiracPotential;

use Stats::Fermi;

sub new {
	my ($class) = @_;
	my $self = {
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

### potential difference
sub delta {

	my ($self, $a, $x, $m, $T, $v) = @_;

	my $DiracFunc = DiracFunc->new;
	my $Boltzmann = Boltzmann->new;
	
	my $DeltaPotential = DeltaPotential->new;

	return $DeltaPotential->difference($a,$x,$m,$T,$v,$DiracFunc,$Boltzmann);

}

### calculation of potential using Lagrangian, difference in number
sub deltadiff {
	my ($self, $a,$x,$m,$T,$v, $dL, $dr_i, $dri, @lambdas, @dfi) = @_;
	 
	my $potential = $self->delta($a,$x,$m,$T,$v);
	my $lagrangian = BoltzmannDiracLagrangian->new()->leftphrase($dL, $dr_i);
	return ($potential - $lagrangian);
}


1;
