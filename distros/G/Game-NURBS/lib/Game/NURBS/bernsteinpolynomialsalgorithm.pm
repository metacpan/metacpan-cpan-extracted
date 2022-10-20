### nth-degree Bernstein polynomials 

### The NURBS book p. 10 

use parent 'algorithm';

sub new {
	my $class = shift;

	$self = SUPER::new->(@_);
}

### $n!
sub fac {
	my ($self, $n) = @_;
	my $res = 1;

	for (my $i = $n; $i > 0; $i--) {
		$res *= $i;
	}

	return $res;
}

### nth-degree Bernstein polynomial
### B_{i,n}(u) = 
sub calculate {
	my ($self, $i, $n, $u) = @_;

	return ($self->fac($n) / ($self->fac($i) * $self->fac($n-$i)) * pow(u,i) * pow(1-$u, $n-$i)); 

}

1;
