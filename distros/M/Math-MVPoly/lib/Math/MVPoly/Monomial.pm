package Math::MVPoly::Monomial;

# Copyright (c) 1998 by Brian Guarraci. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
use Math::MVPoly::Integer;

sub
new
{
	my $self;

	$self = {};

	$self->{COEFFICIENT} 	= undef;
	$self->{VARIABLES}	= {};
	$self->{VARORDER}	= [];
	$self->{VERBOSE}	= 1;

	bless($self);
	return $self;
}

sub
copy
{
        my $self = shift;
	my $m	 = shift;
	my $vars;
	my $f;
	my $copy_vars;
	my $varOrder;
	my $copy_varOrder;

	$self->coefficient($m->coefficient());

	$vars = $m->variables();
	$copy_vars = {%$vars};
	$self->variables($copy_vars);

	$varOrder = $m->varOrder();
	$copy_varOrder = [@$varOrder];
	$self->varOrder($copy_varOrder);
}

sub
coefficient
{
        my $self = shift;
        if (@_) { $self->{COEFFICIENT} = shift }
        return $self->{COEFFICIENT};
}

sub
variables
{
        my $self = shift;
        if (@_) { $self->{VARIABLES} = shift }
        return $self->{VARIABLES};
}

sub
varOrder
{
        my $self = shift;
        if (@_) { $self->{VARORDER} = shift }
        return $self->{VARORDER};
}

sub
verbose
{
        my $self = shift;
        if (@_) { $self->{VERBOSE} = shift }
        return $self->{VERBOSE};
}

sub
fromString
{
	my $self = shift();
	my $string = shift();
	my $i;
	my $c;
	my $h;
	my $p;
	my $f;
	my @ve;
	my @parts;
	my $buildVarOrder;

	@parts = grep {/\S/} ($string =~ /(^[+-]?\d+\.\d+)|(^[+-]?\d+)|(^[+-])|([A-Za-z]\^\d+)|([A-Za-z])/g);

	# determine the coefficient
	$c = $parts[0];
	$i = 1;

	# see if $c is numeric, otherwise deduce the coefficient
	if ($c !~ /^[+-]?\d+/g)
	{
		if ($c eq "-")
		{
			$c = -1;
		}	
		elsif ($c eq "+")
		{
			$c = 1;
		}
		else	
		{
			$i = 0;
			$c = 1;
		}
	}

	$self->coefficient($c*1);

	# build the variable/exponent pairs
	$h = {};

	foreach $p (@parts[$i..$#parts])
	{
		# if there is an exponent, extract it, otherwise default to 1
		if ($p =~ /\^/)
		{
			@ve = split(/\^/,$p);
			$h->{$ve[0]} = $ve[1];
		}
		else
		{
			$h->{$p} = 1; 
		}
	}

	$self->variables($h);
}

sub
toString
{
	my $self = shift();
	my $s;
	my $myVars;
	my $varOrder;
	my $f;
	my $varsExist;
	my @nd;
	my $c;

	@nd = $self->coeff_to_ND();

	$c = $nd[0]/$nd[1];

	if ($c > 0)
	{
		$s = "+";
	}

	$myVars = $self->variables();
	$varOrder = $self->varOrder();

	if ($self->verbose())
	{
		$s .= $self->coefficient();

		foreach $f (@$varOrder)
		{
			if (exists($myVars->{$f}))
			{
				$s .= "$f^".$myVars->{$f}; 
			}
		}	
	}
	else
	{
		if (abs($c) != 1)
		{
			$s .= $self->coefficient();
		}
		elsif ($self->coefficient() == -1)
		{
			$s = "-";
		}	

		$varsExist = 0;

		foreach $f (@$varOrder)
		{
			if (exists($myVars->{$f}))
			{
				$varsExist = 1;
				$s .= "$f";
				if ($myVars->{$f} > 1)
				{
					$s .= "^".$myVars->{$f}; 
				}
			}
		}	

		if (! $varsExist)
		{
			$s .= "1";
		}
	}

	return $s;
}

sub
getSignature
{
	my $self = shift();
	my $s;
	my $myVars;
	my $varOrder;
	my $f;

	if ($self->getTotalDegree() == 0)
	{
		$s = "CONST";
	}
	else
	{
		$myVars = $self->variables();
		$varOrder = $self->varOrder();

		foreach $f (@$varOrder)
		{
			if (exists($myVars->{$f}))
			{
				$s .= "$f^".$myVars->{$f}; 
			}
		}	
	}

	return $s;
}

sub
getTotalDegree
{
	my $self = shift();
	my $deg;
	my $vars;
	my $f;

	$vars = $self->variables();	

	$deg = 0;
	foreach $f (keys %$vars)
	{
		$deg += $vars->{$f};
	}
	
	return $deg;
}

sub
canDivide
{
	my $self = shift;
	my $m	 = shift;
	my $flag;
	my $myVars;
	my $vars;
	my $f;
	
	# does $m have a subset of vars?
	# Is each corresponding exponent <=?

	$flag = 1;

	$myVars = $self->variables();	
	$vars = $m->variables();	

	foreach $f (keys %$myVars)
	{
		if (! exists($vars->{$f}) || $myVars->{$f} > $vars->{$f})
		{
			$flag = 0;
			last;
		}
	}

	return $flag;
}

sub
add
{
	my $self = shift;
	my $m	 = shift;
	my $nm;
	my @pa;
	my @qa;
	my $numer;
	my $denom;
	my $x;
	my $y;
	my $k;
	my $j;

	$nm = Math::MVPoly::Monomial->new();
	$nm->copy($self);

	#
	# calc. the coefficient
	#
	@qa = $self->coeff_to_ND();
	@pa = $m->coeff_to_ND();

	# x/y + k/j = (yk+jx)/yj

	$x = $qa[0];
	$y = $qa[1];
	$k = $pa[0];
	$j = $pa[1];

	$numer = $y*$k + $j*$x; 
	$denom = $y*$j; 

	$nm->coeff_from_ND($numer,$denom);

	return $nm;
}

sub
divide
{
	my $self = shift;
	my $m	 = shift;
	my $nm;
	my $nmVars;
	my $vars;
	my $f;
	my @pa;
	my @qa;
	my $numer;
	my $denom;

	$nm = Math::MVPoly::Monomial->new();
	$nm->copy($self);

	#
	# calc. the coefficient
	#
	@qa = $self->coeff_to_ND();
	@pa = $m->coeff_to_ND();

	$numer = $qa[0]*$pa[1];
	$denom = $qa[1]*$pa[0];

	$nm->coeff_from_ND($numer,$denom);

	#
	# determine the variables and exponents 
	#
	$nmVars = $nm->variables();	
	$vars = $m->variables();	

	foreach $f (keys %$vars)
	{
		if (! exists($nmVars->{$f}))
		{
			$nmVars->{$f} = $vars->{$f};;
		}
		else
		{
			$nmVars->{$f} -= $vars->{$f};
		}
	}

	# at this point, new variables may be present in the monomial
	# and/or one or more exponents may now be 0, so reduce.
	$nm->reduceVariables();

	return $nm;
}

sub
mult
{
	my $self = shift;
	my $m	 = shift;
	my $nm;
	my $nmVars;
	my $vars;
	my $f;
	my @pa;
	my @qa;
	my $numer;
	my $denom;

	$nm = Math::MVPoly::Monomial->new();
	$nm->copy($self);

	#
	# calc. the coefficient
	#
	@qa = $self->coeff_to_ND();
	@pa = $m->coeff_to_ND();

	$numer = $qa[0]*$pa[0];
	$denom = $qa[1]*$pa[1];

	$nm->coeff_from_ND($numer,$denom);

	#
	# determine the variables and exponents 
	#
	$nmVars = $nm->variables();	
	$vars = $m->variables();	

	foreach $f (keys %$vars)
	{
		if (! exists($nmVars->{$f}))
		{
			$nmVars->{$f} = $vars->{$f};;
		}
		else
		{
			$nmVars->{$f} += $vars->{$f};
		}
	}

	# at this point, new variables may be present in the monomial
	# and/or one or more exponents may now be 0, so reduce.
	$nm->reduceVariables();

	return $nm;
}

sub
coeff_to_ND
{
	my $self = shift;
	my $x;
	my @xa;

	$x = $self->coefficient();

	@xa = ($x,1);

	if ($x =~ /\//)
	{
		@xa = split('\/',$x);
	}

	return (@xa);
}

sub
coeff_from_ND
{
	my $self	= shift;
	my $numer	= shift;
	my $denom	= shift;
	my $c;

	if ($numer/$denom != int($numer/$denom))
	{
		$c = "$numer/$denom";
	}
	else
	{
		$c = $numer/$denom;
	}

	$self->coefficient($c);
}

sub
reduceCoefficient
{
	my $self = shift;
	my $i;
	my $j;
	my $r;

	($i,$j) = $self->coeff_to_ND();
	if ($i != 0)
	{
		$r = Math::MVPoly::Integer::gcd($i,$j);
	}
	if ($r > 1)
	{
		$i /= $r;
		$j /= $r;
		$self->coeff_from_ND($i,$j);
	}
}

sub
reduceVariables
{
	my $self = shift;
	my $vars;
	my $k;

	$vars = $self->variables();

	foreach $k (keys %$vars)
	{
		if ($vars->{$k} == 0)
		{
			delete($vars->{$k});
		}
	}
}

sub
getLCM
{
	my $self = shift;
	my $b = shift;
	my $varOrder;
	my $f;
	my $lcm;
	my $a_vars;
	my $b_vars;
	my $lcm_vars;
	my $ea;
	my $eb;
	my $e;

	$lcm = Math::MVPoly::Monomial->new();
	$lcm->copy($self);

	$a_vars = $self->variables();
	$b_vars = $b->variables();
	$lcm_vars = $lcm->variables();

	$varOrder = $self->varOrder();

	foreach $f (@$varOrder)
	{
		$ea = $a_vars->{$f};
		$eb = $b_vars->{$f};
		$lcm_vars->{$f} = ($ea > $eb ? $ea : $eb);
	}	

	return $lcm;
}

1;

__END__

=head1 NAME

Monomial - Perl module implmenting an algebraic monomial

=head1 DESCRIPTION

=over 4

=item new

Return a reference to a new Monomial object.

=for html <p>

=item copy OBJREF

Perform a deep copy of the object referred to by OBJREF.

=for html <p>

=item coefficient VALUE

=for html <p>

=item coefficient

Retrieve the value of the coefficient.  If a value is passed, it is assigned as the new value.

=for html <p>

=item variables

=item variables HASH

Retrieve the value of the variables hash. If a value is passed, it is assigned as the new value.

=for html <p>

=item varOrder

=item varOrder ARRAYREF

Retrieve the value of the variable ordering array reference. If a value is passed, it is assigned as the new value.

=for html <p>

=item fromString STRING

Construct the state of the object from an expression.

=for html <p>

=item toString

Build an algebraic expression string representing the monomial.

=for html <p>

=item getSignature

Create a signature for a monomial such that any two monomials with the same exponents have the same signature.

=for html <p>

=item getTotalDegree

Get the sum the exponents for each variable in the monomial.

=for html <p>

=item canDivide OBJREF

Determine if the input monomial can divide this monomial.

=for html <p>

=item add OBJREF

Add this monial to the input monomial and return the sum.

=for html <p>

=item divide OBJREF

Divide this monomial by the input monomial and return the quotient.

=for html <p>

=item mult OBJREF

Multiply this monomial by the input monomial and return the product.

=for html <p>

=item coeff_to_ND

Constructs an array containing the numerator and denominator of the coefficient.

=for html <p>

=item coeff_from_ND ARRAYREF

Given an array ref containing numerator and denominator, this method builds the coefficient from the numerator and denominator passed in.  The coefficient will be a string if the ratio is non-integer, otherwise it will be reduced to the integer and be a scalar.

=for html <p>

=item reduceCoefficient	

Determines if the coefficient can be simplified to a simpler (smaller) numerator/denominator pair.

=for html <p>

=item reduceVariables

Determines if any variables can be removed from the monomials based on exponent values.

=for html <p>

=item getLCM OBJREF

Given a monomial, determine the LCM of this monomial with the input monomial and return it.

=back

=head1 AUTHOR

Brian Guarraci <bguarrac@hotmail.com>