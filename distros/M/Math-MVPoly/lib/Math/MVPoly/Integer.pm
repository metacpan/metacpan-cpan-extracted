package Math::MVPoly::Integer;

# Copyright (c) 1998 by Brian Guarraci. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
use Math::MVPoly::Monomial;

sub
gcd
{
	my $u;
	my $v;
	my $q;
	my $t;
	my $g;

	my $a = $_[0];
	my $b = $_[1];

	$u = [1,0,abs($a)];
	$v = [0,1,abs($b)];

	while($$v[2])
	{
		$q = int($$u[2]/$$v[2]);
		$t = [  $$u[0] - $$v[0]*$q, 
			$$u[1] - $$v[1]*$q, 
			$$u[2] - $$v[2]*$q];
		$u = $v;
		$v = $t;
	}
 
	$g = $$u[2];

	return $g;
}

1;

__END__

=head1 NAME

Integer - a collection of integer operations

=head1 DESCRIPTION

Integer - a collection of integer operations to support the varioous algebraic opertions in the Algebra module.

=over 4

=item gcd A,B

Use Knuth's algorithm to find the gcd of integers A and B. 

=back

=head1 AUTHOR

Brian Guarraci <bguarrac@hotmail.com>
