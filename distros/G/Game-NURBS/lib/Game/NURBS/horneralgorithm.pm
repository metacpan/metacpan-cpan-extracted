### Compute a point on power basis curve

### The NURBS book p. 7

use parent 'algorithm';

sub new {
	my $class = shift;

	$self = SUPER::new->(@_);
}

sub calculate {
	 my ($self, @a, $n, $u0, $C) = @_;

	$C = @a[$n];
	
	for (my $i = $n - 1; $i >= 0; $i--) {
		$C = $C * $u0 + @a[$i];
	}

	return $C;
}
