package Math::MVPoly::Polynomial;

# Copyright (c) 1998 by Brian Guarraci. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
use Math::MVPoly::Monomial;
use Math::MVPoly::Integer;

$Math::MVPoly::VERSION = '0.2b';

sub
new
{
	my $self;
	my $m;
	
	$self = {};

	$self->{MONOMIALS} = [];
	$self->{MONORDER} = 'grlex';
	$self->{VARORDER} = [];
	$self->{VERBOSE} = 0;

	bless($self);           # but see below
	return $self;
}

sub
copy
{
	my $self = shift;
	my $p	 = shift;
	my $monomials;
	my $varOrder;
	my $copy_monomials;
	my $copy_varOrder;
	my $copy_order;
	my $m;
	my $f;

	$copy_order = $p->monOrder();
	$self->monOrder($copy_order);

	$monomials = $p->monomials();
	$copy_monomials = [@$monomials];
	$self->monomials($copy_monomials);

	$varOrder = $p->varOrder();
	$copy_varOrder = [@$varOrder];
	$self->varOrder($copy_varOrder);

	return $self;
}

sub
monOrder
{
	my $self = shift;
	if (@_)
	{
		$self->{MONORDER} = shift;
	}
	return($self->{MONORDER});
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
	if (@_)
	{
		$self->{VARORDER} = shift;
	}
	return($self->{VARORDER});
}

sub
monomials
{
	my $self = shift;
	if (@_)
	{
		$self->{MONOMIALS} = shift;
	}
	return($self->{MONOMIALS});
}

sub
insertMonomial
{
	my $self = shift;
	my $m = shift;
	my $monomials;

	$monomials = $self->monomials();

	push(@$monomials, $m);

	$self->simplify();
	$self->applyOrder();
}

sub
simplify
{
	my $self = shift;
	my $monomials;
	my %hash;
	my $m;
	my $hm;
	my $f;
	my $sig;

	$monomials = $self->monomials();

	foreach $m (@$monomials)
	{
		$sig = $m->getSignature();

		if (exists($hash{$sig}))
		{
			$hm = $hash{$sig};
			$hm = $hm->add($m);
			$hash{$sig} = $hm;

			if ($hm->coefficient() == 0)
			{
				delete $hash{$sig};
				next;
			}
			else
			{
			}
		}
		else
		{
			$hash{$sig} = $m;
		}

		$m->reduceCoefficient();
	}

	$monomials = [values %hash];

	$self->monomials($monomials);	
}

sub
fromString
{
	my $self = shift;
	my $eq = shift;
	my $m;
	my $pat;
	my @parts;
	my $f;
	my $varOrder;

	$_ = $eq;

	s/\s//g;	# remove all white space
	s/\+/\ \+/g;	# move a space in front of all +'s
	s/\-/\ \-/g;	# move a space in front of all -'s

	@parts = grep {/\S/} split();

	$varOrder = $self->varOrder();

	foreach $f (@parts)
	{
		$m = Math::MVPoly::Monomial->new();
		$m->varOrder([@$varOrder]);
		$m->fromString($f);
		$self->insertMonomial($m);
	}
}

sub
toString
{
	my $self = shift;
	my $s;
	my $m;
	my $sig;
	my $monomials;

	$monomials = $self->monomials();

	$s = "";


	if ($#$monomials < 0)
	{
		$s .= "0";
	}
	else
	{
		foreach $m (@$monomials)
		{
			$m->verbose($self->verbose());
			$s .= $m->toString();
		}

		if (! $self->verbose())
		{
			if ($s =~ /^\+/)
			{
				$s = substr($s,1);
			}
		}
	}

	return $s;
}

sub
applyOrder
{
	my $self = shift;
	my $monomials;
	my @list;
	my $f;
	my $m;

	$monomials = $self->monomials();

	$self->monomials($monomials);

	if ($self->monOrder() eq 'lex')
	{
		$monomials = [sort SortByLexOrder @$monomials]; 
	}
	elsif ($self->monOrder() eq 'grlex')
	{
		$monomials = [sort SortByGrLex @$monomials]; 
	}
	elsif ($self->monOrder() eq 'grevlex')
	{
		$monomials = [sort SortByGrevLex @$monomials]; 
	}
	elsif ($self->monOrder() eq 'tdeg')
	{
		$monomials = [sort SortByTotalDegree @$monomials]; 
	}

	$self->monomials($monomials);
}

sub
SortByLexOrder
{
	my $left;
	my $right;
	my $varOrder;
	my $a_vars;
	my $b_vars;
	my $f;

	# proceed down the variable order to perform lex order
	$varOrder = $a->varOrder();

	$a_vars = $a->variables();
	$b_vars = $b->variables();

	$left = 0;
	$right = 0;

	foreach $f (@$varOrder)
	{
		if ($a_vars->{$f} != $b_vars->{$f})
		{
			if ($a_vars->{$f} > $b_vars->{$f})
			{
				$right = 1;
			}
			else
			{
				$left = 1;
			}
			last;
		}
	}						

	$left <=> $right;
}

sub
SortByGrevLex
{
	my $left;
	my $right;
	my $varOrder;
	my $a_vars;
	my $b_vars;
	my $f;

	$left = $b->getTotalDegree();
	$right = $a->getTotalDegree();

	if ($b->getTotalDegree() == $a->getTotalDegree())
	{
		# proceed down the variable order to perform lex order
		$varOrder = $a->varOrder();

		$a_vars = $a->variables();
		$b_vars = $b->variables();

		$left = 0;
		$right = 0;

		foreach $f (@$varOrder)
		{
			if ($a_vars->{$f} != $b_vars->{$f})
			{
				if ($a_vars->{$f} < $b_vars->{$f})
				{
					$right = 1;
				}
				else
				{
					$left = 1;
				}
				last;
			}
		}						
	}

	$left <=> $right;
}

sub
SortByGrLex
{
	my $left;
	my $right;
	my $varOrder;
	my $a_vars;
	my $b_vars;
	my $f;

	$left = $b->getTotalDegree();
	$right = $a->getTotalDegree();

	if ($b->getTotalDegree() == $a->getTotalDegree())
	{
		# proceed down the variable order to perform lex order
		$varOrder = $a->varOrder();

		$a_vars = $a->variables();
		$b_vars = $b->variables();

		$left = 0;
		$right = 0;

		foreach $f (@$varOrder)
		{
			if ($a_vars->{$f} != $b_vars->{$f})
			{
				if ($a_vars->{$f} > $b_vars->{$f})
				{
					$right = 1;
				}
				else
				{
					$left = 1;
				}
				last;
			}
		}						
	}

	$left <=> $right;
}

sub
SortByTotalDegree
{
	$b->getTotalDegree() <=> $a->getTotalDegree(); 
}

sub
getLT
{
	my $self = shift;
	my $m;
	my $monomials;

	$monomials = $self->monomials();
	$m = Math::MVPoly::Monomial->new();
	$m->copy($$monomials[0]);

	return($m);
}

sub
isNotZero
{
	my $self = shift;
	my $g	 = shift; 
	my $flag;
	my $monomials;

	$monomials = $self->monomials();

	$flag = 0;

	if ($#$monomials >= 0)
	{
		$flag = 1;
	}

	return($flag);
}

sub
mult
{
	my $self = shift;
	my $q	 = shift;
	my $myMonomials;
	my $monomials;
	my $f;
	my $p;
	my $z;
	my $m;

	$p = Math::MVPoly::Polynomial->new();

	$myMonomials = $self->monomials();

	if (ref($q) eq "Math::MVPoly::Monomial")
	{
		$f = $q;
		$q = Math::MVPoly::Polynomial->new();
		$q->insertMonomial($f);
	}

	$monomials = $q->monomials();

	foreach $f (@$myMonomials)
	{
		foreach $m (@$monomials)
		{
			$z = $f->mult($m); 
			$p->insertMonomial($z);
		}
	}

	return $p;
}

sub
add
{
	my $self = shift;
	my $q	 = shift; 
	my $p;
	my $monomials;
	my $f;
	my $m;

	$p = Math::MVPoly::Polynomial->new();
	$p->copy($self);

	if (ref($q) eq "Math::MVPoly::Monomial")
	{
		$f = $q;
		$q = Math::MVPoly::Polynomial->new();
		$q->insertMonomial($f);
	}

	$monomials = $q->monomials();

	foreach $f (@$monomials)
	{
		$m = Math::MVPoly::Monomial->new();
		$m->copy($f);		
		$p->insertMonomial($f);
	}

	return $p;
}

sub
subtract
{
	my $self = shift;
	my $q	 = shift; 
	my $p;
	my $monomials;	
	my $f;
	my $neg;
	my $m;

	$p = Math::MVPoly::Polynomial->new();
	$p->copy($self);

	if (ref($q) eq "Math::MVPoly::Monomial")
	{
		$f = $q;
		$q = Math::MVPoly::Polynomial->new();
		$q->insertMonomial($f);
	}

	$monomials = $q->monomials();

	$neg = Math::MVPoly::Monomial->new();
	$neg->fromString("-1");

	foreach $f (@$monomials)
	{
		$m = $f->mult($neg);
		$p->insertMonomial($m);
	}

	return($p);
}

sub
divide
{
	my $self = shift;
	my $ft	 = shift; 
	my $divisionOccured;
	my $lt_p;
	my $lt_fi;
	my $at;
	my $m;
	my $z;
	my $q;
	my $r;
	my $p;
	my $s;
	my $i;

	if (ref($ft) ne "ARRAY")
	{
		$ft = [$ft];
	}

	$s = $#$ft;
	$at = [];

	# initialize the output variables
	foreach $i (0..$s)
	{
		push(@$at, Math::MVPoly::Polynomial->new());
	}
	$r = Math::MVPoly::Polynomial->new();

	$p = Math::MVPoly::Polynomial->new();
	$p->copy($self);	# f is $self

	while($p->isNotZero())
	{
		$i = 0;
		$divisionOccured = 0;

		while($i <= $s && !$divisionOccured)
		{
			$lt_fi = $$ft[$i]->getLT();
			$lt_p = $p->getLT();
			if ($lt_fi->canDivide($lt_p))
			{
				$m = $lt_p->divide($lt_fi);
				$$at[$i] = $$at[$i]->add($m);
				$z = $$ft[$i]->mult($m);
				$p = $p->subtract($z);
				$divisionOccured = 1; 
			}
			else
			{
				$i++;
			}
		}
		if (! $divisionOccured)
		{
			$z = $p->getLT();
			$r = $r->add($z);
			$p = $p->subtract($z);
		}
	}

	return [@$at,$r];
}

sub
gcd
{
	my $self = shift;
	my $g	 = shift; 
	my $h;
	my $e;
	my $s;
	my $i;
	my $r;

	$h = Math::MVPoly::Polynomial->new();
	$h->copy($self);

	$s = Math::MVPoly::Polynomial->new();
	$s->copy($g);

	while($s->isNotZero())
	{
		$e = $h->divide($s);
		$r = $$e[1];
		$h->copy($s);
		$s->copy($r);
	}	

	return ($h)
}

sub
reduce
{
	my $self = shift;
	my $monomials;
	my $m;
	my $numerGCD;
	my $denomGCD;
	my $i;
	my $j;
	my $r;
	my $z;
	my $np;
	my $np2;
	my $n;

	# reduction goals:
	#
	# try to get as many 1's as coefficients as possible
	# make the coefficient of the first monomial (if more than one) > 0
	#
	# ASIDE: there is a lot of work being done here...but this is no trivial task
	# to reduce a polynomial into a simpler form
	#

	$monomials = $self->monomials();

	# determine the gcd for the numerators and denominators
	$m = $$monomials[0];
	($i,$j) = $m->coeff_to_ND();
	$numerGCD = $i;
	$denomGCD = $j;
	
	foreach $m (@$monomials[1..$#$monomials])
	{
		($i,$j) = $m->coeff_to_ND();
		$numerGCD = Integer::gcd($numerGCD, $i);
		$denomGCD = Integer::gcd($denomGCD, $j);
	}

	$z = Math::MVPoly::Monomial->new();
	$z->coeff_from_ND(1,$numerGCD);
	$np = Math::MVPoly::Polynomial->new();

	# divide through by the numerator gcd
	foreach $m (@$monomials)
	{
		$n = $m->mult($z); 
		$np = $np->add($n);
	}

	$z = Math::MVPoly::Monomial->new();
	$z->coefficient($denomGCD);

	$np2 = Math::MVPoly::Polynomial->new();

	$monomials = $np->monomials();

	# multiply through by the denominator gcd
	foreach $m (@$monomials)
	{
		$n = $m->mult($z); 
		$np2 = $np2->add($n);
	}

	# see if the first coefficient is > 0
	$m = $np2->getLT();

	if ($m->coefficient() < 0)
	{
		$z = Math::MVPoly::Monomial->new();
		$z->fromString("-1");
		$np2 = $np2->mult($z);	
	}

	$self->copy($np2);
}

sub
spoly
{
	my $self = shift;
	my $g = shift;
	my $lcm;
	my $q;
	my $p1;
	my $p2;
	my $spoly;
	my $lt_g;
	my $lt_f;
	my $f;

	#
	# S(f,g) = (x^l/LT(f))*f - (x^l/LT(g))*g
	#	
	# where x is a monomial with coefficients l, the LCM of LT(g) and LT(f) where 
	#
	# l(i) = max(a(i), B(i)), a = LT(f), B = LT(g), and i is the ith exponent
	#

	$f = $self;

	$lt_f = $f->getLT();
	$lt_g = $g->getLT();

	$lcm = $lt_f->getLCM($lt_g);

	$q = $lcm->divide($lt_f);
	$p1 = $f->mult($q);

	$q = $lcm->divide($lt_g);
	$p2 = $g->mult($q);
	
	$spoly = $p1->subtract($p2);
	
	return $spoly;	
}

1;

__END__

=head1 NAME

Polynomial - Perl module implementing an algebraic polynomial

=head1 DESCRIPTION

=over 4

=item new

Create a new zero polynomial and return it to the caller.

=for html <p>

=item copy OBJREF

Perform a deep copy of the polynomial object referenced by OBJREF.

=for html <p>

=item monOrder

=item monOrder STRING

Return the current monomial ordering.  If an argument is passed, it is assigned as the new monomial ordering.  The valid orderings are: 

	tdeg		- total degree (single variable case only)
	lex		- pure lexicographic ordering
	grlex		- graded lex
	grevlex 	- graded reverse lex

=for html <p>

=item varOrder

=item varOrder ARRAYREF

Return the current variable ordering as an array reference.  If an argument is passed, it is assigned as the new variable ordering.  For example,

	$poly->varOrder(['x','y','z']);

assigns the variable ordering x > y > z.

=for html <p>

=item monomials

=item monomials HASHREF

Returns the current collection of monomials.  If an argument is passed, it is assigned as the new collection of monomials.

=for html <p>

=item insertMonomial OBJREF

Performs a copy of the monomial referred to by OBJREF and inserts it into the monomial collection.

=for html <p>

=item simplify

Attempt to unify monomials with the same 'signature' (see getSignature) through addition.

=for html <p>

=item fromString STRING

Construct the state of the polynomial from the algebraic expressin represented in STRING.  For example,

	$poly->fromString("xyz+x^2y^4+x+2");

would create four monomials: xyz, x^2y^4, x, and 2.  The previous monomials contained in the polynomial are destroyed.

=for html <p>

=item toString

Convert the current state of the polynomial into a string and return it to the caller.  This string can be sent back in via fromString and be used to reconstruct the polynomial.

=for html <p>

=item applyOrder

Order the monomials according to the current monomial ordering setting.

=for html <p>

=item SortByLexOrder

(Internal) Perform sort.

=for html <p>

=item SortByGrevLex

(Internal) Perform sort.

=for html <p>

=item SortByGrLex

(Internal) Perform sort.

=for html <p>

=item SortByTotalDegree

(Internal) Perform sort.

=for html <p>

=item getLT

Get the leading term of the polynomial and return it to the caller.

=for html <p>

=item isNotZero

Return a boolean indiciating wether or not the polynomial is a zero polynomial or not.

=for html <p>

=item mult OBJREF

Perform polynomial multiplication using this polynomial and the one referred to by OBJREF.  Return a new polynomial containing the product.

=for html <p>

=item add OBJREF

Perform polynomial addition using this polynomial and the one referred to by OBJREF.  Return a new polynomial containing the sum.

=for html <p>

=item subtract OBJREF

Perform polynomial subtraction using this polynomial and the one referred to by OBJREF.  Return a new polynomial containing the difference.

=for html <p>

=item divide OBJREF

Perform polynomial division using this polynomial and the one referred to by OBJREF.  Return an array reference containing the quotients and the remainder.

=for html <p>

=item gcd OBJREF

Determine the polynomial greatest common divisor with respect to this polynomial and the one referred to by OBJREF.  Return a new polynomial containing the gcd.

=for html <p>

=item reduce

Attempt to achieve two goals: 

	1) Get as many 1's as coefficients as possible
	2) If the leading term's coefficient is negative multiply all the coefficients by -1.

=for html <p>

=item spoly

Determine the polynomial SPOLY with respect to this polynomial and the one referred to by OBJREF.  Return a new polynomial containing the SPOLY.

=back

=head1 AUTHOR

Brian Guarraci <bguarrac@hotmail.com>