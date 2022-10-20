### nth-degree Bezier curve definition

### The NURBS book p. 9 

use parent 'algorithm';

sub new {
	my $class = shift;

	$self = SUPER::new->(@_);
}

### B_{i,n} are Bernstein polynomials, see bernsteinpolynomialsalgorithm.pm
### it uses a simple xyz coordinate list as a control point for the bezier curve
### One can use this with a nested list of points (which are themselves $p->xyz)
### see point.pm
### NOTE for the B. polynomials 0 <= u <= 1, in @Bin for points on the curve
### nth-degree Bernstein polynomial
### B_{i,n}(u)
### The following function is just a collision method C(u), a Bezier curve.

sub calculate {
	my ($self, @Bin, @Pointxyz) = @_;

	my $p = point->new(0,0,0);
	my $l = length(@Pointxyz); 
	my $s = $l-1;

	while (--$l >= 0) {
		$p->setx($p->getx + @Bin[$l-$s]*@{@Pointxyz[$l-$s]}[0]);
		$p->sety($p->gety + @Bin[$l-$s]*@{@Pointxyz[$l-$s]}[1]);
		$p->setz($p->getz + @Bin[$l-$s]*@{@Pointxyz[$l-$s]}[2]);

		$s -= 2; 
	}

	return $p;
}

### this works somehwat for non-sorted polygons in 3D space
sub calculate_for_z_order {
	my ($self, @Bin, @Pointxyz) = @_;

	my $z = 0;
	my $l = length(@Pointxyz); 
	my $s = $l-1;

	while (--$l >= 0) {
		$z += @Bin[$l-$s]*@{@Pointzyz[$l-$s]}[2];
	
		$s -= 2;
	}

	return $z;
}

1;
