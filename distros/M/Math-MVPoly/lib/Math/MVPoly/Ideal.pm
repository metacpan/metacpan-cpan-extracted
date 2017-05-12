package Math::MVPoly::Ideal;

# Copyright (c) 1998 by Brian Guarraci. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
use Math::MVPoly::Polynomial;

sub
new
{
	my $self;
	
	$self = {};
	$self->{POLYNOMIALS} = [];
	$self->{VERBOSE} = 0;
	bless($self);

	return $self;
}

sub
copy
{
	my $self = shift;
	my $p	 = shift;
	my $polynomials;
	my $copy_polynomials;

	$polynomials = $p->polynomials();
	$copy_polynomials = [@$polynomials];
	$self->polynomials($copy_polynomials);
}

sub
polynomials
{
	my $self = shift;
	if (@_)
	{
		$self->{POLYNOMIALS} = shift;
	}
	return($self->{POLYNOMIALS});
}

sub
verbose
{
	my $self = shift;
	if (@_)
	{
		$self->{VERBOSE} = shift;
	}
	return($self->{VERBOSE});
}

sub
varOrder
{
	my $self = shift;
	my $varOrder = shift;
	my $p;
	my $polynomials;

	$polynomials = $self->polynomials();

	foreach $p (@$polynomials)
	{
		$p->varOrder($varOrder);
	}
}

sub
monOrder
{
	my $self = shift;
	my $monOrder = shift;
	my $p;
	my $polynomials;

	$polynomials = $self->polynomials();

	foreach $p (@$polynomials)
	{
		$p->monOrder($monOrder);
	}
}

sub
applyOrder
{
	my $self = shift;
	my $p;
	my $polynomials;

	$polynomials = $self->polynomials();

	foreach $p (@$polynomials)
	{
		$p->applyOrder();
	}
}

sub
appendPolynomial
{
	my $self = shift;
	my $p = shift;
	my $polynomials;

	$polynomials = $self->polynomials();

	push(@$polynomials, $p);
}

sub
toString
{
	my $self = shift;
	my $s;
	my $p;
	my $polynomials;
	my $i;

	$polynomials = $self->polynomials();

	$s = "";

	foreach $i (0..$#$polynomials)
	{
		$p = $$polynomials[$i];
		$p->verbose($self->verbose());
		$s .= $p->toString();
		if ($i < $#$polynomials)
		{
			$s .= ", ";
		}
	}

	return $s;
}

sub
set
{
	my $self = shift;
	my $list = shift;
	my $p;
	my $q;

	foreach $p (@$list)
	{
		$q = Math::MVPoly::Polynomial->new();
		$q->copy($p);
		$self->appendPolynomial($q);
	}	
}

sub
getSize
{
	my $self = shift;
	my $size;
	my $polynomials;

	$polynomials = $self->polynomials();

	$size = $#$polynomials;
	
	return $size;
}

sub
getPolynomial
{
	my $self = shift;
	my $i = shift;
	my $polynomials;
	my $p;

	$polynomials = $self->polynomials();
	
	$p = $$polynomials[$i];

	return $p;
}

sub
getGBasis
{
	my $self = shift;
	my $G;
	my $GP;
	my $changed;
	my $s;
	my $q;
	my $p;
	my $r;
	my $i;
	my $j;
	my $div_results;
	my $rem;
	
	$GP = Math::MVPoly::Ideal->new();

	$G = Math::MVPoly::Ideal->new();
	$G->copy($self);


	do
	{
		$changed = 0;

		$GP->copy($G);
		$s = $GP->getSize();

		foreach $i (0..($s-1))
		{
			foreach $j (($i+1)..$s)
			{
				$p = $G->getPolynomial($i);
				$q = $G->getPolynomial($j);
				$r = $p->spoly($q); 

				$div_results = $r->divide($GP->polynomials());
				$rem = $$div_results[$#$div_results];

				if ($rem->isNotZero())
				{
					$G->appendPolynomial($rem);
					$changed = 1;
				}
			}
		}
	}
	while($changed);

	return $G;
}

1;

__END__

=head1 NAME

Ideal - A simple (subset) of an algebraic Ideal.

=head1 DESCRIPTION

=over 4

=item new

creates a new Ideal instance with no polynomials. 

=for html <p>

=item copy OBJREF 

performs a deep copy of object reference passed in.

=for html <p>

=item polynomials

=item polynomials LIST 

access/modify polynomial list in object.  If there is any input,  it is taken as the new value of polynomials.  The value of polynomials is returned to the caller.

=for html <p>

=item appendPolynomial OBJREF

takes as input a reference to polynomial to append to list; a copy of it is made and then appended.

=for html <p>

=item toString

generates a string representing the list of polynomials and returns this string to the caller.

=for html <p>

=item set LIST

list of polynomials to set the ideal to. destroys current polynomial list and copies the new list.

=for html <p>

=item getSize

returns the number of polynomials in the ideal generator.

=for html <p>

=item getPolynomial

returns the ith polynomial from the list. 

=for html <p>

=item getGBasis

generates a groebner basis using Buchberger's simplest algorithm. 

=back

=head1 AUTHOR

Brian Guarraci <bguarrac@hotmail.com>
