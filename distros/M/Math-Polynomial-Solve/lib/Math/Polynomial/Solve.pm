package Math::Polynomial::Solve;

require 5.010001;
use strict;
use warnings;
use utf8;
use Carp;

use Math::Complex;
use Math::Utils qw(:polynomial :utility);
use Exporter;
our @ISA = qw(Exporter);


#
# Three # for "I am here" messages.
# Four # for variable dumps.
# Five # for a dump of the companion matrix.
# Six # for sturm structs (sign chain, etc).
#
#use Smart::Comments q(######);

@ISA = qw(Exporter);

#
# Export only on request.
#
our %EXPORT_TAGS = (
	'classical' => [ qw(
		linear_roots
		quadratic_roots
		cubic_roots
		quartic_roots
	) ],
	'numeric' => [ qw(poly_roots
		poly_option
		build_companion
		balance_matrix
		hqr_eigen_hessenberg
	) ],
	'sturm' => [ qw(
		poly_real_root_count
		poly_sturm_chain
		sturm_real_root_range_count
		sturm_bisection
		sturm_bisection_roots
		sturm_sign_count
		sturm_sign_chain
		sturm_sign_minus_inf
		sturm_sign_plus_inf
	) ],
	'utility' => [ qw(
		epsilon
		laguerre
		newtonraphson
		poly_iteration
		poly_nonzero_term_count
		poly_tolerance
	) ],
);

our @EXPORT_OK = (
	@{ $EXPORT_TAGS{'classical'} },
	@{ $EXPORT_TAGS{'numeric'} },
	@{ $EXPORT_TAGS{'sturm'} },
	@{ $EXPORT_TAGS{'utility'} } );

our @EXPORT = qw( ascending_order );

our $VERSION = '2.80';

#
# See the END block.
#
my $ascending_order_called = 0;

#
# Options to set or unset to force poly_roots() to use different
# methods of solving.
#
# hessenberg (default 1): set to 1 to force poly_roots() to use the QR
# Hessenberg method regardless of the degree of the polynomial.  Set to zero
# to force poly_roots() uses one of the specialized routines (linerar_roots(),
# quadratic_roots(), etc) if the degree of the polynomial is less than five.
#
# root_function (default 0): set to 1 to force poly_roots() to use
# Math::Complex's root(-c/a, n) function if the polynomial is of the form
# ax**n + c.
#
# varsubst (default 0): try to reduce the degree of the polynomial through
# variable substitution before solving.
#
my %option = (
	hessenberg => 1,
	root_function => 0,
	varsubst => 0,
);

#
# Iteration limits. The Hessenberg matrix method and the Laguerre method run
# continuously until they converge upon an answer. The iteration limits are
# there to prevent the loops from running forever if they fail to converge.
#
my %iteration = (
	hessenberg => 60,
	newtonraphson => 60,
	laguerre => 60,
	sturm_bisection => 100,
);

#
# Some values here are placeholders only, and will get
# replaced in the BEGIN block.
#
my %tolerance = (
	newtonraphson => 1e-14,
	laguerre => 1e-14,
);

#
# Set up the epsilon variable, the value that is, in the floating-point
# math of the computer, the smallest value a variable can have before
# it is indistinguishable from zero when adding it to one.
#
my $epsilon;

BEGIN
{
	$epsilon = 0.125;
	my $epsilon2 = $epsilon/2.0;

	while (1.0 + $epsilon2 > 1.0)
	{
		$epsilon = $epsilon2;
		$epsilon2 /= 2.0;
	}

	$tolerance{laguerre} = 2 * $epsilon;
	$tolerance{newtonraphson} = 2 * $epsilon;
}

#
# Flag to determine whether calling order is
# ($an_1, $an_2, $an_3, ...) or if it is
# ($a0, $a1, $a2, $a3, ...)
#
my $ascending_flag = 0;		# default 0, in a later version it will be 1.

=pod

=encoding UTF-8

=head1 NAME

Math::Polynomial::Solve - Find the roots of polynomial equations.

=head1 SYNOPSIS

    use Math::Complex;  # The roots may be complex numbers.
    use Math::Polynomial::Solve qw(poly_roots);

    my @x = poly_roots(@coefficients);

or

    use Math::Complex;  # The roots may be complex numbers.
    use Math::Polynomial::Solve qw(:numeric);  # See the EXPORT section

    #
    # Find roots using the matrix method.
    #
    my @x = poly_roots(@coefficients);

    #
    # Alternatively, use the classical methods instead of the matrix
    # method if the polynomial degree is less than five.
    #
    poly_option(hessenberg => 0);
    @x = poly_roots(@coefficients);

or

    use Math::Complex;  # The roots may be complex numbers.
    use Math::Polynomial::Solve qw(:classical);  # See the EXPORT section

    #
    # Find the polynomial roots using the classical methods.
    #

    # Find the roots of ax + b
    my @x1 = linear_roots($a, $b);

    # Find the roots of ax**2 + bx +c
    my @x2 = quadratic_roots($a, $b, $c);

    # Find the roots of ax**3 + bx**2 +cx + d
    my @x3 = cubic_roots($a, $b, $c, $d);

    # Find the roots of ax**4 + bx**3 +cx**2 + dx + e
    my @x4 = quartic_roots($a, $b, $c, $d, $e);

or

    use Math::Complex;  # The roots may be complex numbers.
    use Math::Polynomial;
    use Math::Polynomial::Solve qw(:classical ascending_order);

    ascending_order(1); # Change default coefficient order for M::P::S.

    #
    # Form 8*x**3 - 6*x - 1
    #
    my $p1 = Math::Polynomial->new(-1, -6, 0, 8);

    #
    # Use Math::Polynomial's coefficient order.
    # If ascending_order() had not been called,
    # the statement would be:
    #
    # my @roots = poly_roots(reverse $p1->coefficients);
    #
    my @roots = poly_roots($p1->coefficients);

or

    use Math::Polynomial::Solve qw(:sturm);

    #
    # Find the number of unique real roots of the polynomial.
    #
    my $no_of_unique_roots = poly_real_root_count(@coefficients);

=head1 DESCRIPTION

This package supplies a set of functions that find the roots of
polynomials, along with some utility functions.

Roots will be either real or of type L<Math::Complex>.

Functions making use of the Sturm sequence are also available, letting you
find the number of real roots present in a range of X values.

In addition to the root-finding functions, the internal functions have
also been exported for your use.

=cut

#
# $asending = ascending_order();
# $oldorder = ascending_order($neworder);
#
#
sub ascending_order
{
	my $ascend = $ascending_flag;

	if (scalar @_ > 0)
	{
		$ascending_flag = ($_[0] == 0)? 0: 1;
		$ascending_order_called  = 1;
	}

	return $ascend;
}

#
# ($new_coefficients_ref, $varsubst) = poly_analysis(@coefficients);
#
# If the polynomial has evenly spaced gaps of zero coefficients, reduce
# the polynomial through variable substitution.
#
# For example, a degree-6 polynomial like 9x**6 + 128x**3 + 7
# can be reduced to a polynomial 9y**2 + 128y + 7, where y = x**3.
#
# After solving a quadratic instead of a sextic, the actual roots of
# the original equation are found by taking the cube roots of each
# root of the quadratic.
#
# Not exported.
sub poly_analysis
{
	my(@coefficients) = ($ascending_flag)? reverse @_: @_;
	my @czp;
	my $m = 1;

	#
	# Is the count of coefficients a multiple of any of the primes?
	#
	# Realistically I don't expect any gaps that can't be handled by
	# the first three prime numbers, but it's not much of a waste of
	# space to go up to 31.
	#
	@czp = grep(($#coefficients % $_) == 0,
		(2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31)
	);

	#
	# Any coefficients zero at the non-N degrees? (1==T,0==F).
	#
	#### @czp
	#
	if (@czp)
	{
		for my $j (0..$#coefficients)
		{
			if (abs($coefficients[$j]) > $epsilon)
			{
				@czp = grep(($j % $_) == 0, @czp);
			}
		}

		#
		# The remaining list of primes represent the gap size
		# between non-zero coefficients.
		#
		map(($m *= $_), @czp);

		#### Substitution degree: $m
	}

	#
	# If there's a sequence of zero-filled gaps in the coefficients,
	# reduce the polynomial by degree $m and check again for the
	# next round of factors (e.g., X**8 + X**4 + 1 needs two rounds
	# to get to a factor of 4).
	#
	if ($m > 1)
	{
		my @alt_coefs;
		push @alt_coefs, $coefficients[$_*$m] for (0..$#coefficients/$m);
		my($cf, $m1) = poly_analysis(@alt_coefs);
		@coefficients = @$cf;
		$m *= $m1;
	}

	return \@coefficients, $m;
}

=head1 EXPORT

Currently there is one default export, L<ascending_order|ascending_order()>.

The remaining functions may be individually named in an export list,
but there are also four export tags:
L<classical|Classical Functions>,
L<numeric|Numeric Functions>,
L<sturm|Sturm Functions>, and
L<utility|Utility Functions>.

=head2 EXPORTED BY DEFAULT

=head3 ascending_order()

Changes the default order of the coefficents to the functions.

When Math::Polynomial::Solve was originally written, it followed the
calling convention of L<Math::Polynomial>, using the highest degree
coefficient, followed by the next highest degree coefficient, and so
on in descending order.

Later Math::Polynomial was re-written, and the order of the coefficients were
put in ascending order, e.g.:

    use Math::Polynomial;

    #
    # Create the polynomial 8*x**3 - 6*x - 1.
    #
    $fpx = Math::Polynomial->new(-1, -6, 0, 8);

If you use Math::Polynomial with this module, it will probably be
more convenient to change the default parameter list of
Math::Polynomial::Solve's functions, using the ascending_order() function:

    use Math::Polynomial;
    use Math::Polynomial::Solve qw(:classical :numeric);

    ascending_order(1);

    my $fp4 = Math::Polynomial->interpolate([1 .. 4], [14, 19, 25, 32]);

    #
    # Find roots of $fp4.
    #
    my @fp4_roots = quartic_roots($fp4->coefficients);

or

    my @fp4_roots = poly_roots($fp4->coefficients);

If C<ascending_order(1)> had not been called, the previous line of code
would have been written instead as

    my @fp4_roots = poly_roots(reverse $fp4->coefficients);

The function is a way to help with the change in the API when version 3.00 of
this module is released. At that point coefficients will be in ascending
order by default, and you will need to use C<ascending_order(0)> to use the
old (current) style.

=head2 Numeric Functions

These are the functions that calculate the polynomial's roots through numeric
algorithms. They are all exported under the tag "numeric".

=head3 poly_roots()

Returns the roots of a polynomial equation, regardless of degree.
Unlike the other root-finding functions, it will check for coefficients
of zero for the highest power, and 'step down' the degree of the
polynomial to the appropriate case. Additionally, it will check for
coefficients of zero for the lowest power terms, and add zeros to its
root list before calling one of the root-finding functions.

By default, C<poly_roots()> will use the Hessenberg matrix method for solving
polynomials. This can be changed by calling L</poly_options()>.

The method of poly_roots() is almost equivalent to

    @x = hqr_eigen_hessenberg(
          balance_matrix(build_companion(@coefficients))
          );

except this wouldn't check for leading and trailing zero coefficients, and it
ignores the settings of C<poly_options()>.

=cut

sub poly_roots
{
	my(@coefficients) = ($ascending_flag)? reverse @_: @_;
	my(@x, @zero_x);
	my $subst_degree = 1;

	#
	#### @coefficients
	#
	# Check for zero coefficients in the higher-powered terms.
	#
	shift @coefficients while (scalar @coefficients and
				   abs($coefficients[0]) < $epsilon);

	if (@coefficients == 0)
	{
		carp "All coefficients are zero\n";
		return (0);
	}

	#
	# How about zero coefficients in the low terms?
	#
	while (scalar @coefficients and
	       abs($coefficients[$#coefficients]) < $epsilon)
	{
		push @zero_x, 0;
		pop @coefficients
	}

	#
	# If the polynomial is of the form ax**n + c, and $option{root_function}
	# is set, use the Math::Complex::root() function to return the roots.
	#
	### %option
	#
	if ($option{root_function} and
	    poly_nonzero_term_count(@coefficients) == 2)
	{
		return  @zero_x,
			root(-$coefficients[$#coefficients]/$coefficients[0],
			     $#coefficients);
	}

	#
	# Next do some analysis of the coefficients.
	# See if we can reduce the size of the polynomial by
	# doing some variable substitution.
	#
	if ($option{varsubst})
	{
		my $cf;
		($cf, $subst_degree) = poly_analysis(@coefficients);
		@coefficients = @$cf if ($subst_degree > 1);
	}

	#
	# If the remaining polynomial is a quintic or higher, or
	# if $option{hessenberg} is set, continue with the matrix
	# calculation.
	#
	#### @coefficients
	#### $subst_degree
	#

	#
	# The following root solvers do their own coefficient
	# reversing, so undo the earlier reversal now.
	#
	@coefficients = reverse @coefficients if ($ascending_flag);

	if ($option{hessenberg} or $#coefficients > 4)
	{
		#
		# QR iterations from the matrix.
		#
		@x = hqr_eigen_hessenberg(
			balance_matrix(build_companion(@coefficients))
			);
	}
	elsif ($#coefficients == 4)
	{
		@x = quartic_roots(@coefficients);
	}
	elsif ($#coefficients == 3)
	{
		@x = cubic_roots(@coefficients);
	}
	elsif ($#coefficients == 2)
	{
		@x = quadratic_roots(@coefficients);
	}
	elsif ($#coefficients == 1)
	{
		@x = linear_roots(@coefficients);
	}

	@x = map(root($_, $subst_degree), @x) if ($subst_degree > 1);

	return  @zero_x, @x;
}


=head3 poly_option()

Set options that affect the behavior of the C<poly_roots()> function. All
options are set to either 1 ("on") or 0 ("off"). See also L</poly_iteration()>
and L</poly_tolerance()>.

Options may be set and saved:

    #
    # Set a few options...
    #
    poly_option(hessenberg => 0, root_function => 1);

    #
    # Get all of the current options and their values.
    #
    my %all_options = poly_option();

    #
    # Set some options but save the former option values
    # for later.
    #
    my %changed_options = poly_option(hessenberg => 1, varsubst => 1);

The current options available are:

=over 4

=item 'hessenberg'

Use the QR Hessenberg matrix method to solve the polynomial. By default, this
is set to 1. If set to 0, C<poly_roots()> uses one of the L<classical|Classical Functions>
root-finding functions listed below, I<if> the degree of the polynomial is four
or less.

=item 'root_function'

Use the L<root()|Math::Complex/OPERATIONS> function from Math::Complex if the
polynomial is of the form C<ax**n + c>. This will take precedence over the other
solving methods.

=item 'varsubst'

Reduce polynomials to a lower degree through variable substitution, if possible.

For example, with C<varsubst> set to one and the polynomial to solve being
C<9x**6 + 128x**3 + 21>, C<poly_roots()> will reduce the polynomial to
C<9y**2 + 128y + 21> (where C<y = x**3>),
and solve the quadratic (either classically or numerically, depending
on the hessenberg option). Taking the cube root of each quadratic root
completes the operation.

This has the benefit of having a simpler matrix to solve, or if the
C<hessenberg> option is set to zero, has the effect of being able to use one of
the classical methods on a polynomial of high degree. In the above example, the
order-six polynomial gets solved with the quadratic_roots() function if the
hessenberg option is zero.

Currently the variable substitution is fairly simple and will only look
for gaps of zeros in the coefficients that are multiples of the prime numbers
less than or equal to 31 (2, 3, 5, et cetera).

=back

=cut

sub poly_option
{
	my %opts = @_;
	my %old_opts;

	return %option if (scalar @_ == 0);

	for my $okey (keys %opts)
	{
		#
		# If this is a real option, save its old value, then set it.
		#
		if (exists $option{$okey})
		{
			$old_opts{$okey} = $option{$okey};
			$option{$okey} = ($opts{$okey})? 1: 0;
		}
		else
		{
			carp "poly_option(): unknown key $okey.";
		}
	}

	return %old_opts;
}

=head3 build_companion

Creates the initial companion matrix of the polynomial. Returns an array
of arrays (the internal representation of a matrix). This may be used as
an argument to the L<Math::Matrix> contructor:

    my @cm = build_companion(@coef);

    my $m = Math::Matrix->new(@cm);
    $m->print();

The Wikipedia article at L<http://en.wikipedia.org/wiki/Companion_matrix/> has
more information on the subject.

=cut

#
# Perl code to find roots of a polynomial translated by Nick Ing-Simmons
# from FORTRAN code by Hiroshi Murakami.
#
# From the netlib archive: http://netlib.bell-labs.com/netlib/search.html
# In particular http://netlib.bell-labs.com/netlib/opt/companion.tgz
#
sub build_companion
{
	my @coefficients = ($ascending_flag)? reverse @_: @_;
	my $n = $#coefficients - 1;
	my @h;

	#
	### build_companion called with: @coefficients
	#
	# First step:  Divide by the leading coefficient and negate.
	#
	my $cn = - (shift @coefficients);
	map($_ /= $cn, @coefficients);

	#
	# Next: set up the diagonal matrix.
	#
	for my $i (0 .. $n)
	{
		$h[$i][$n] = pop @coefficients;
		map($h[$i][$_] = 0.0, 0 .. $n - 1);
	}

	map($h[$_][$_ - 1] = 1.0, 1 .. $n);

	return @h;
}


=head3 balance_matrix

Balances the matrix (makes the rows and columns have similar norms) created
by build_companion() by applying a matrix transformation with a diagonal
matrix of powers of two.

This is used to help prevent any rounding errors that occur if the elements
of the matrix differ greatly in magnitude.

=cut

#       BASE is the base of the floating point representation on the machine.
#       It is 16 for base 16 float : for example, IBM system 360/370.
#       It is 2  for base  2 float : for example, IEEE float.
sub BASE ()    { 2 }
sub BASESQR () { BASE * BASE }

#
# @matrix = balance_matrix(@cm);
#
# Balance the companion matrix created by build_companion().
#
# Return an array of arrays representing the N by N matrix.
#
# In the :numeric export set.
#
sub balance_matrix
{
	my @h = @_;
	my $n = $#h;

	#
	### Balancing the unsymmetric matrix A.
	#
	##### @h
	#
	# Perl code translated by Nick Ing-Simmons from FORTRAN code
	# by Hiroshi Murakami.
	#
	#  The Fortran code is based on the Algol code "balance" from paper:
	#  "Balancing a Matrix for Calculation of Eigenvalues and Eigenvectors"
	#  by B. N. Parlett and C. Reinsch, Numer. Math. 13, 293-304(1969).
	#
	#  Note: The only non-zero elements of the companion matrix are touched.
	#
	my $noconv = 1;
	while ($noconv)
	{
		$noconv = 0;
		for my $i (0 .. $n)
		{
			#
			# Touch only non-zero elements of companion.
			#
			my $c;
			if ($i != $n)
			{
				$c = abs($h[$i + 1][$i]);
			}
			else
			{
				$c = 0.0;
				for my $j (0 .. $n - 1)
				{
					$c += abs($h[$j][$n]);
				}
			}

			my $r;
			if ($i == 0)
			{
				$r = abs($h[0][$n]);
			}
			elsif ($i != $n)
			{
				$r = abs($h[$i][$i - 1]) + abs($h[$i][$n]);
			}
			else
			{
				$r = abs($h[$i][$i - 1]);
			}

			next if ($c == 0.0 || $r == 0.0);

			my $g = $r / BASE;
			my $f = 1.0;
			my $s = $c + $r;
			while ( $c < $g )
			{
				$f = $f * BASE;
				$c = $c * BASESQR;
			}

			$g = $r * BASE;
			while ($c >= $g)
			{
				$f = $f / BASE;
				$c = $c / BASESQR;
			}

			if (($c + $r) < 0.95 * $s * $f)
			{
				$g = 1.0 / $f;
				$noconv = 1;

				#C Generic code.
				#C   do $j=1,$n
				#C       $h($i,$j)=$h($i,$j)*$g
				#C   enddo
				#C   do $j=1,$n
				#C       $h($j,$i)=$h($j,$i)*$f
				#C   enddo
				#C begin specific code. Touch only non-zero elements of companion.
				if ($i == 0)
				{
					$h[0][$n] *= $g;
				}
				else
				{
					$h[$i][$i - 1] *= $g;
					$h[$i][$n] *= $g;
				}
				if ($i != $n)
				{
					$h[$i + 1][$i] *= $f;
				}
				else
				{
					for my $j (0 .. $n)
					{
						$h[$j][$i] *= $f;
					}
				}
			}
		}	# for $i
	}	# while $noconv

	#
	### Returning balanced matrix.
	##### @h
	#
	return @h;
}


=head3 hqr_eigen_hessenberg

Returns the roots of the polynomial equation by solving the matrix created by
C<build_companion()> and C<balance_matrix()>. See L</poly_roots()>.

=cut

sub hqr_eigen_hessenberg
{
	my @h = @_;
	my $n = $#h;

	#
	### hqr_eigen_hessenberg()
	#
	# Eigenvalue Computation by the Householder QR method for the
	# Real Hessenberg matrix.
	#
	# Perl code translated by Nick Ing-Simmons from FORTRAN code
	# by Hiroshi Murakami.
	#
	# The Fortran code is based on the Algol code "hqr" from the paper:
	#   "The QR Algorithm for Real Hessenberg Matrices"
	#   by R. S. Martin, G. Peters and J. H. Wilkinson,
	#   Numer. Math. 14, 219-231(1970).
	#
	my($p, $q, $r);
	my $t = 0.0;

	my @roots;

	ROOT:
	while ($n >= 0)
	{
		my $its = 0;
		my $na  = $n - 1;

		while ($its < $iteration{hessenberg})
		{
			my($w, $x, $y);

			#
			# Look for single small sub-diagonal element;
			#
			my $l = 0;
			for my $d (reverse 1 .. $n)
			{
				if (abs( $h[$d][ $d - 1 ] ) <= $epsilon *
				    (abs( $h[ $d - 1 ][ $d - 1 ] ) +
				     abs( $h[$d][$d] ) ) )
				{
					$l = $d;
					last;
				}
			}

			$x = $h[$n][$n];

			if ($l == $n)
			{
				#
				# One (real) root found.
				#
				$n--;
				push @roots, $x + $t;
				next ROOT;
			}

			$y = $h[$na][$na];
			$w = $h[$n][$na] * $h[$na][$n];

			if ($l == $na)
			{
				$p = ( $y - $x ) / 2;
				$q = $p * $p + $w;
				$y = sqrt( abs($q) );
				$x += $t;

				if ($q > 0.0)
				{
					#
					# Real pair.
					#
					$y = -$y if ( $p < 0.0 );
					$y += $p;
					push @roots, $x - $w / $y;
					push @roots, $x + $y;
				}
				else
				{
					#
					# Complex or twin pair.
					#
					push @roots, $x + $p - $y * i;
					push @roots, $x + $p + $y * i;
				}

				$n -= 2;
				next ROOT;
			}

			croak "Too many iterations ($its) at n=$n\n" if ($its >= $iteration{hessenberg});

			if ($its && $its % 10 == 0)
			{
				#
				# Form exceptional shift.
				#
				### Exceptional shift at: $its
				#

				$t += $x;
				for my $i (0 .. $n)
				{
					$h[$i][$i] -= $x;
				}

				my $s = abs($h[$n][$na]) + abs($h[$na][$n - 2]);
				$y = 0.75 * $s;
				$x = $y;
				$w = -0.4375 * $s * $s;
			}

			$its++;

			#
			### Look for two consecutive small
			### sub-diagonal elements.
			#
			my $m = $l;	# Set in case we fall through the loop.
			for my $d (reverse $l .. $n - 2)
			{
				my $z = $h[$d][$d];
				my $s = $y - $z;
				$r = $x - $z;
				$p = ($r * $s - $w) / $h[$d + 1][$d] + $h[$d][$d + 1];
				$q = $h[$d + 1][$d + 1] - $z - $r - $s;
				$r = $h[$d + 2][$d + 1];

				$s = abs($p) + abs($q) + abs($r);
				$p /= $s;
				$q /= $s;
				$r /= $s;

				#
				# The sub-diagonal check doesn't get made for
				# the last iteration of the loop, and the only
				# reason we have the loop continue up to this
				# point is to set $p, $q, and $r.
				#
				last if ($d == $l);

				if (abs($h[$d][$d - 1]) * (abs($q) + abs($r)) <=
					$epsilon * abs($p) * (
						  abs($h[$d - 1][$d - 1]) +
						  abs($z) +
						  abs($h[$d + 1][$d + 1])
					))
				{
					$m = $d;
					last;
				}
			}

			#
			#### $n
			#### $l
			#### $m
			#
			for my $i (($m + 2) .. $n)
			{
				$h[$i][$i - 2] = 0.0;
			}
			for my $i (($m + 3) .. $n)
			{
				$h[$i][$i - 3] = 0.0;
			}

			#
			# Double QR step involving rows $l to $n and
			# columns $m to $n.
			#
			for my $k ($m .. $na)
			{
				my $z;
				my $notlast = ($k != $na);
				if ($k != $m)
				{
					$p = $h[$k][$k - 1];
					$q = $h[$k + 1][$k - 1];
					$r = ($notlast)? $h[$k + 2][$k - 1]: 0.0;

					$x = abs($p) + abs($q) + abs($r);
					next if ( $x == 0.0 );

					$p /= $x;
					$q /= $x;
					$r /= $x;
				}

				my $s = sqrt($p * $p + $q * $q + $r * $r);
				$s = -$s if ($p < 0.0);

				if ($k != $m)
				{
					$h[$k][$k - 1] = -$s * $x;
				}
				elsif ($l != $m)
				{
					$h[$k][$k - 1] *= -1;
				}

				$p += $s;
				$x = $p / $s;
				$y = $q / $s;
				$z = $r / $s;
				$q /= $p;
				$r /= $p;

				#
				# Row modification.
				#
				for my $j ($k .. $n)
				{
					$p = $h[$k][$j] + $q * $h[$k + 1][$j];

					if ($notlast)
					{
						$p += $r * $h[ $k + 2 ][$j];
						$h[ $k + 2 ][$j] -= $p * $z;
					}

					$h[ $k + 1 ][$j] -= $p * $y;
					$h[$k][$j] -= $p * $x;
				}

				my $j = $k + 3;
				$j = $n if ($j > $n);

				#
				# Column modification.
				#
				for my $i ($l .. $j)
				{
					$p = $x * $h[$i][$k] +
					     $y * $h[$i][$k + 1];

					if ($notlast)
					{
						$p += $z * $h[$i][$k + 2];
						$h[$i][$k + 2] -= $p * $r;
					}

					$h[$i][$k + 1] -= $p * $q;
					$h[$i][$k] -= $p;
				}
			}	# for $k
		}	# while $its
	}	# while $n
	return @roots;
}


=head2 Classical Functions

These are the functions that solve polynomials via the classical methods.
Quartic, cubic, quadratic, and even linear equations may be solved with
these functions. They are all exported under the tag "classical".

L</poly_roots()> will use these functions I<if> the hessenberg option
is set to 0, I<and if> the degree of the polynomial is four or less.

The leading coefficient C<$a> must always be non-zero for the classical
functions.

=head3 linear_roots()

Here for completeness's sake more than anything else. Returns the
solution for

    ax + b = 0

by returning C<-b/a>. This may be in either a scalar or an array context.

=cut

sub linear_roots
{
	my($a, $b) = ($ascending_flag)? reverse @_: @_;

	if (abs($a) < $epsilon)
	{
		carp "The coefficient of the highest power must not be zero!\n";
		return ();
	}

	return wantarray? (-$b/$a): -$b/$a;
}


=head3 quadratic_roots()

Gives the roots of the quadratic equation

    ax**2 + bx + c = 0

using the well-known quadratic formula. Returns a two-element list.

=cut

sub quadratic_roots
{
	my($a, $b, $c) = ($ascending_flag)? reverse @_: @_;

	if (abs($a) < $epsilon)
	{
		carp "The coefficient of the highest power must not be zero!\n";
		return ();
	}

	return (0, -$b/$a) if (abs($c) < $epsilon);

	my $dis_sqrt = sqrt($b*$b - $a * 4 * $c);

	$dis_sqrt = -$dis_sqrt if ($b < $epsilon);	# Avoid catastrophic cancellation.

	my $xt = ($b + $dis_sqrt)/-2;

	return ($xt/$a, $c/$xt);
}


=head3 cubic_roots()

Gives the roots of the cubic equation

    ax**3 + bx**2 + cx + d = 0

by the method described by R. W. D. Nickalls (see the L</ACKNOWLEDGMENTS>
section below). Returns a three-element list. The first element will
always be real. The next two values will either be both real or both
complex numbers.

=cut

sub cubic_roots
{
	my($a, $b, $c, $d) = ($ascending_flag)? reverse @_: @_;
	my @x;

	if (abs($a) < $epsilon)
	{
		carp "The coefficient of the highest power must not be zero!\n";
		return @x;
	}

	#
	# We're calling exported functions that also check
	# the $ascending_flag. To avoid reversing the reversed,
	# temporarily set the flag to zero and reset before returning.
	#
	my $temp_ascending_flag = $ascending_flag;
	$ascending_flag = 0;

	if (abs($d) < $epsilon)
	{
		@x = quadratic_roots($a, $b, $c);
		$ascending_flag = $temp_ascending_flag;
		return (0, @x);
	}

	my $xN = -$b/3/$a;
	my $yN = $d + $xN * ($c + $xN * ($b + $a * $xN));

	my $two_a = 2 * $a;
	my $delta_sq = ($b * $b - 3 * $a * $c)/(9 * $a * $a);
	my $h_sq = 4/9 * ($b * $b - 3 * $a * $c) * $delta_sq**2;
	my $dis = $yN * $yN - $h_sq;
	my $twothirds_pi = (2 * pi)/3;

	#
	###            cubic_roots() calculations...
	#### $two_a
	#### $delta_sq
	#### $h_sq
	#### $dis
	#
	if ($dis > $epsilon)
	{
		#
		### Cubic branch 1, $dis is greater than  0...
		#
		# One real root, two complex roots.
		#
		my $dis_sqrt = sqrt($dis);
		my $r_p = $yN - $dis_sqrt;
		my $r_q = $yN + $dis_sqrt;
		my $p = cbrt( abs($r_p)/$two_a );
		my $q = cbrt( abs($r_q)/$two_a );

		$p = -$p if ($r_p > 0);
		$q = -$q if ($r_q > 0);

		$x[0] = $xN + $p + $q;
		$x[1] = $xN + $p * exp($twothirds_pi * i)
			    + $q * exp(-$twothirds_pi * i);
		$x[2] = ~$x[1];
	}
	elsif ($dis < -$epsilon)
	{
		#
		### Cubic branch 2, $dis is less than  0...
		#
		# Three distinct real roots.
		#
		my $theta = acos(-$yN/sqrt($h_sq))/3;
		my $delta = sqrt($b * $b - 3 * $a * $c)/(3 * $a);
		my $two_d = 2 * $delta;

		@x = ($xN + $two_d * cos($theta),
			$xN + $two_d * cos($twothirds_pi - $theta),
			$xN + $two_d * cos($twothirds_pi + $theta));
	}
	else
	{
		#
		### Cubic branch 3, $dis equals 0, within epsilon...
		#
		# abs($dis) <= $epsilon (effectively zero).
		#
		# Three real roots (two or three equal).
		#
		my $delta = cbrt($yN/$two_a);

		@x = ($xN + $delta, $xN + $delta, $xN - 2 * $delta);
	}

	$ascending_flag = $temp_ascending_flag;
	return @x;
}

=head3 quartic_roots()

Gives the roots of the quartic equation

    ax**4 + bx**3 + cx**2 + dx + e = 0

using Ferrari's method (see the L</ACKNOWLEDGMENTS> section below). Returns
a four-element list. The first two elements will be either
both real or both complex. The next two elements will also be alike in
type.

=cut

sub quartic_roots
{
	my($a,$b,$c,$d,$e) = ($ascending_flag)? reverse @_: @_;
	my @x = ();

	if (abs($a) < $epsilon)
	{
		carp "Coefficient of highest power must not be zero!\n";
		return @x;
	}

	#
	# We're calling exported functions that also check
	# the $ascending_flag. To avoid reversing the reversed,
	# temporarily set the flag to zero and reset before returning.
	#
	my $temp_ascending_flag = $ascending_flag;
	$ascending_flag = 0;

	if (abs($e) < $epsilon)
	{
		@x = cubic_roots($a, $b, $c, $d);
		$ascending_flag = $temp_ascending_flag;
		return (0, @x);
	}

	#
	# First step:  Divide by the leading coefficient.
	#
	$b /= $a;
	$c /= $a;
	$d /= $a;
	$e /= $a;

	#
	# Second step: simplify the equation to the
	# "resolvent cubic"  y**4 + fy**2 + gy + h.
	#
	# (This is done by setting x = y - b/4).
	#
	my $b4 = $b/4;

	#
	# The f, g, and h values are:
	#
	my $f = $c -
		6 * $b4 * $b4;
	my $g = $d +
		2 * $b4 * (-$c + 4 * $b4 * $b4);
	my $h = $e +
		$b4 * (-$d + $b4 * ($c - 3 * $b4 * $b4));

	#
	###            quartic_roots calculations
	#### $b4
	#### $f
	#### $g
	#### $h
	#
	if (abs($h) < $epsilon)
	{
		#
		### Quartic branch 1, $h equals 0, within epsilon...
		#
		# Special case: h == 0.  We have a cubic times y.
		#
		@x = (0, cubic_roots(1, 0, $f, $g));
	}
	elsif (abs($g * $g) < $epsilon)
	{
		#
		### Quartic branch 2, $g equals 0, within epsilon...
		#
		# Another special case: g == 0.  We have a quadratic
		# with y-squared.
		#
		# (We check $g**2 because that's what the constant
		# value actually is in Ferrari's method, and it is
		# possible for $g to be outside of epsilon while
		# $g**2 is inside, i.e., "zero").
		#
		my($p, $q) = quadratic_roots(1, $f, $h);
		$p = sqrt($p);
		$q = sqrt($q);
		@x = ($p, -$p, $q, -$q);
	}
	else
	{
		#
		### Quartic branch 3, Ferrari's method...
		#
		# Special cases don't apply, so continue on with Ferrari's
		# method.  This involves setting up the resolvent cubic
		# as the product of two quadratics.
		#
		# After setting up conditions that guarantee that the
		# coefficients come out right (including the zero value
		# for the third-power term), we wind up with a 6th
		# degree polynomial with, fortunately, only even-powered
		# terms.  In other words, a cubic with z = y**2.
		#
		# Take a root of that equation, and get the
		# quadratics from it.
		#
		my $z;
		($z, undef, undef) = cubic_roots(1, 2*$f, $f*$f - 4*$h, -$g*$g);

		#### $z

		my $alpha = sqrt($z);
		my $rho = $g/$alpha;
		my $beta = ($f + $z - $rho)/2;
		my $gamma = ($f + $z + $rho)/2;

		@x = quadratic_roots(1, $alpha, $beta);
		push @x, quadratic_roots(1, -$alpha, $gamma);
	}

	$ascending_flag = $temp_ascending_flag;
	return ($x[0] - $b4, $x[1] - $b4, $x[2] - $b4, $x[3] - $b4);
}

=head2 Sturm Functions

These are the functions that create and make use of the Sturm sequence.
They are all exported under the tag "sturm".

=head3 poly_real_root_count()

Return the number of I<unique>, I<real> roots of the polynomial.

    $unique_roots = poly_real_root_count(@coefficients);

For example, the equation C<(x + 3)**3> forms the polynomial
C<x**3 + 9x**2 + 27x + 27>, but since all three of its roots are identical,
C<poly_real_root_count(1, 9, 27, 27)> will return 1.

Likewise, C<poly_real_root_count(1, -8, 25)> will return 0 because the two roots
of C<x**2 -8x + 25> are both complex.

This function is the all-in-one function to use instead of

    my @chain = poly_sturm_chain(@coefficients);

    return sturm_sign_count(sturm_sign_minus_inf(\@chain)) -
            sturm_sign_count(sturm_sign_plus_inf(\@chain));

if you don't intend to use the Sturm chain for anything else.

=cut

sub poly_real_root_count
{
	my @coefficients = @_;

	my @chain = poly_sturm_chain(@coefficients);

	return sturm_sign_count(sturm_sign_minus_inf(\@chain)) -
		sturm_sign_count(sturm_sign_plus_inf(\@chain));
}

=head3 sturm_real_root_range_count()

Return the number of I<unique>, I<real> roots of the polynomial between two X values.

    my($x0, $x1) = (0, 1000);

    my @chain = poly_sturm_chain(@coefficients);
    $root_count = sturm_real_root_range_count(\@chain, $x0, $x1);

This is equivalent to:

    my($x0, $x1) = (0, 1000);

    my @chain = poly_sturm_chain(@coefficients);
    my @signs = sturm_sign_chain(\@chain, [$x0, $x1]);
    $root_count = sturm_sign_count(@{$signs[0]}) - sturm_sign_count(@{$signs[1]});

=cut

sub sturm_real_root_range_count
{
	my($chain_ref, $x0, $x1) = @_;

	my @signs = sturm_sign_chain($chain_ref, [$x0, $x1]);

	my $count0 = sturm_sign_count(@{$signs[0]});
	my $count1 = sturm_sign_count(@{$signs[1]});

	#
	###### (from, to): join(", ", ($x0, $x1))
	###### sign count from: $count0
	###### sign count to: $count1
	#
	return $count0 - $count1;
}


=head3 sturm_bisection()

Finds the boundaries around the roots of a polynomial function,
using the root count method of Sturm.

    @boundaries = sturm_bisection(\@chain, $from, $to);

The elements of @boundaries will be a list of two-element arrays, each
one bracketing a root.

It will not bracket complex roots.

This allows you to use a different root-finding function than laguerre(),
which is the default function used by sturm_bisection_roots().

=cut

sub sturm_bisection
{
	my($chain_ref, $from, $to) = @_;
	my(@coefficients) = @{${$chain_ref}[0]};
	my @boundaries;

	#
	#### @coefficients
	#
	#
	# If we have a linear equation, just solve the thing. We're not
	# going to find a useful second derivative, after all. (Which
	# would raise the question of why we're here without a useful
	# Sturm chain, but never mind...)
	#
	if ($#coefficients == 1)
	{
		my $root = linear_roots(@coefficients);

		#
		# But make sure the root is within the
		# asked-for range.
		#
		return () if ($root < $from or $root > $to);
		return ([$root, $root]);
	}

	#
	# Do Sturm bisection here.
	#
	my $range_count = sturm_real_root_range_count($chain_ref, $from, $to);

	#
	# If we're down to one root in this range, use Laguerre's method
	# to hunt it down.
	#
	return () if ($range_count == 0);
	return ([$from, $to]) if ($range_count == 1);

	#
	# More than one root in this range, so subdivide
	# until each root has its own range.
	#
	my $its = 0;

	ROOT:
	for (;;)
	{
		my $mid = ($to + $from)/2.0;
		my $frommid_count = sturm_real_root_range_count($chain_ref, $from, $mid);
		my $midto_count = sturm_real_root_range_count($chain_ref, $mid, $to);

		#
		#### $its
		#### $from
		#### $mid
		#### $to
		#### $frommid_count
		#### $midto_count
		#

		#
		# Bisect again if we only narrowed down to a range
		# containing all the roots.
		#
		if ($frommid_count == 0)
		{
			$from = $mid;
		}
		elsif ($midto_count == 0)
		{
			$to = $mid;
		}
		else
		{
			#
			# We've divided the roots between two ranges. Do it
			# again until each range has a single root in it.
			#
			push @boundaries, sturm_bisection($chain_ref, $from, $mid);
			push @boundaries, sturm_bisection($chain_ref, $mid, $to);
			last ROOT;
		}
		croak "Too many iterations ($its) at mid=$mid\n" if ($its >= $iteration{sturm_bisection});
		$its++;
	}
	return @boundaries;
}


=head3 sturm_bisection_roots()

Return the I<real> roots counted by L</sturm_real_root_range_count()>.
Uses L</sturm_bisection()> to bracket the roots of the polynomial,
then uses L</laguerre()> to close in on each root.

    my($from, $to) = (-1000, 0);
    my @chain = poly_sturm_chain(@coefficients);
    my @roots = sturm_bisection_roots(\@chain, $from, $to);

As it is using the Sturm functions, it will find only the real roots.

=cut

sub sturm_bisection_roots
{
	my($chain_ref, $from, $to) = @_;
	my $cref0 = ${$chain_ref}[0];
	my @boundaries = sturm_bisection($chain_ref, $from, $to);
	my @roots;

	my $temp_ascending_flag = $ascending_flag;
	$ascending_flag = 1;

	#
	#### sturm_bisection() returns: @boundaries
	#
	for my $bracket (@boundaries)
	{
		my ($left, $right) = @$bracket;
		push @roots, laguerre($cref0, ($left + $right)/2.0);
	}

	$ascending_flag = $temp_ascending_flag;

	return @roots;
}


=head3 poly_sturm_chain()

Returns the chain of Sturm functions used to evaluate the number of roots of a
polynomial in a range of X values. The chain is a list of coefficient
references, the coefficients being stored in ascending order.

If you feed in a sequence of X values to the Sturm functions, you can tell where
the (real, not complex) roots of the polynomial are by counting the number of
times the Y values change sign.

See L</poly_real_root_count()> above for an example of its use.

=cut

sub poly_sturm_chain
{
	my @coefficients = @_;
	my $degree = $#coefficients;
	my(@chain, @remd);
	my($f1, $f2);

	@coefficients = reverse @coefficients unless ($ascending_flag);

	$f1 = [@coefficients];
	$f2 = pl_derivative(\@coefficients);

	push @chain, $f1;

	#
	# Start the first links of the chain.
	#
	SKIPIT: {
		last SKIPIT if ($degree < 1); #return @chain if ($degree < 1);

		push @chain, $f2;

		last SKIPIT if ($degree < 2); #return @chain if ($degree < 2);

		#
		###### poly_sturm_chain chain before do loop:
		###### @chain
		#
		do
		{
			my ($q, $r) = pl_div($f1, $f2);

			#
			# Remove any leading zeros in the remainder.
			#
			@remd = @{$r};
			pop @remd while (@remd and abs($remd[$#remd]) < $epsilon);

			$f1 = $f2;
			$f2 = (@remd)? [map {$_ * -1} @remd]: [0];
			push @chain, $f2;
		}
		while ($#remd > 0);
	}

	#
	###### poly_sturm_chain:
	###### @chain
	#
	return @chain;
}

=head3 sturm_sign_count()

Counts and returns the number of sign changes in a sequence of signs,
such as those returned by the L</Sturm Sign Sequence Functions>

See L</poly_real_root_count()> and L</sturm_real_root_range_count()> for
examples of its use.

=cut

sub sturm_sign_count
{
	my @sign_seq = @_;
	my $scnt = 0;

	my $s1 = shift @sign_seq;
	for my $s2 (@sign_seq)
	{
		$scnt++ if ($s1 != $s2);
		$s1 = $s2;
	}

	return $scnt;
}


=head3 Sturm Sign Sequence Functions

=head4 sturm_sign_chain()

=head4 sturm_sign_minus_inf()

=head4 sturm_sign_plus_inf()

These functions return the array of signs that are used by the functions
L</poly_real_root_count()> and L</sturm_real_root_range_count()> to find
the number of real roots in a polynomial.

In normal use you will probably never need to use them, unless you want
to examine the internals of the Sturm functions:

    #
    # Examine the sign changes that occur at each endpoint of
    # the x range.
    #
    my(@coefficients) = (1, 4, 7, 23);
    my(@xvals) = (-12, 12);

    my @chain = poly_sturm_chain( @coefficients);
    my @signs = sturm_sign_chain(\@chain, \@xvals);  # An array of arrays.

    print "\nPolynomial: [", join(", ", @coefficients), "]\n";

    for my $j (0..$#signs)
    {
        my @s = @{$signs[$j]};
        print $xval[$j], "\n",
              "\t", join(", ", @s), "], sign count = ",
              sturm_sign_count(@s), "\n\n";
    }

Similar examinations can be made at plus and minus infinity:

    #
    # Examine the sign changes that occur between plus and minus
    # infinity.
    #
    my @coefficients = (1, 4, 7, 23);

    my @chain = poly_sturm_chain( @coefficients);
    my @smi = sturm_sign_minus_inf(\@chain);
    my @spi = sturm_sign_plus_inf(\@chain);

    print "\nPolynomial: [", join(", ", @coefficients), "]\n";

    print "Minus Inf:\n",
          "\t", join(", ", @smi), "], sign count = ",
          sturm_sign_count(@smi), "\n\n";

    print "Plus Inf:\n",
          "\t", join(", ", @spi), "], sign count = ",
          sturm_sign_count(@spi), "\n\n";

=cut

#
# @signs = sturm_minus_inf(\@chain);
#
# Return an array of signs from the chain at minus infinity.
#
# In the :sturm export set.
#
sub sturm_sign_minus_inf
{
	my($chain_ref) = @_;
	my @signs;

	for my $c (@$chain_ref)
	{
		my @coefficients = @$c;
		push @signs, sign($coefficients[$#coefficients]) *
			((($#coefficients & 1) == 1)? -1: 1);
	}

	return @signs;
}

#
# @signs = sturm_plus_inf(\@chain);
#
# Return an array of signs from the chain at infinity.
#
# In the :sturm export set.
#
sub sturm_sign_plus_inf
{
	my($chain_ref) = @_;
	my @signs;

	for my $c (@$chain_ref)
	{
		my @coefficients = @$c;
		push @signs, sign($coefficients[$#coefficients]);
	}

	return @signs;
}

#
# @sign_chains = sturm_sign_chain(\@chain, \@xvals);
#
# Return an array of signs for each x-value passed in each function in
# the Sturm chain.
#
# In the :sturm export set.
#
sub sturm_sign_chain
{
	my($chain_ref, $xvals_ref) = @_;
	my $fn_count = $#$chain_ref;
	my $x_count = $#$xvals_ref;
	my @sign_chain;

	push @sign_chain, [] for (0..$x_count);

	for my $p_ref (@$chain_ref)
	{
		my @ysigns = sign(pl_evaluate($p_ref, $xvals_ref));

		#
		# We just retrieved the signs of a single function across
		# our x-vals. We want it the other way around; signs listed
		# by x-val across functions.
		#
		# (list of lists)
		# |
		# v
		#      f0   f1   f2   f3   f4   ...
		# x0    -    -    +    -    +    (list 0)
		#
		# x1    +    -    -    +    +    (list 1)
		#
		# x2    +    -    +    +    +    (list 2)
		#
		# ...
		#
		for my $j (0..$x_count)
		{
			push @{$sign_chain[$j]}, shift @ysigns;
		}
	}

	#
	###### sturm_sign_chain() returns
	###### @sign_chain: @sign_chain
	#
	return @sign_chain;
}


=head2 Utility Functions

These are internal functions used by the other functions listed above
that may also be useful to the user, or which affect the behavior of
other functions. They are all exported under the tag "utility".

=head3 epsilon()

Returns the machine epsilon value that was calculated when this module was
loaded.

The value may be changed, although this in general is not recommended.

    my $old_epsilon = epsilon($new_epsilon);

The previous value of epsilon may be saved to be restored later.

The Wikipedia article at L<http://en.wikipedia.org/wiki/Machine_epsilon/> has
more information on the subject.

=cut

sub epsilon
{
	my $eps = $epsilon;
	$epsilon = $_[0] if (scalar @_ > 0);
	return $eps;
}

=head3 laguerre()

A numerical method for finding a root of an equation, especially made
for polynomials.

    @roots = laguerre(\@coefficients, \@xvalues);
    push @roots, laguerre(\@coefficients, $another_xvalue);

For each x value the function will attempt to find a root closest to it.
The function will return real roots only.

This is the function used by L</sturm_bisection_roots()> after using
L</sturm_bisection()> to narrow its search to a range containing a single
root.

=cut

sub laguerre
{
	no Math::Complex;
	my($p_ref, $xval_ref) = @_;
	my $n = $#$p_ref;
	my @xvalues;
	my @roots;

	$p_ref = [reverse @$p_ref] unless ($ascending_flag);

	#
	# Allow some flexibility in sending the x-values.
	#
	if (ref $xval_ref eq "ARRAY")
	{
		@xvalues = @$xval_ref;
	}
	else
	{
		#
		# It could happen. Someone might type \$x instead of $x.
		#
		@xvalues = ((ref $xval_ref eq "SCALAR")? $$xval_ref: $xval_ref);
	}

	for my $x (@xvalues)
	{
		#
		#### laguerre looking near: $x
		#### Coefficient: @$p_ref
		#### Degree: $n
		#
		my $its = 0;

		ROOT:
		for (;;)
		{
			#
			# Get the values of the function and its first and
			# second derivatives at X.
			#
			my($y, $dy, $d2y) = pl_dxevaluate($p_ref, $x);

			if (abs($y) <= $tolerance{laguerre})
			{
				push @roots, $x;
				last ROOT;
			}

			#
			#### At Iteration: $its
			#### x: $x
			#### f(x): $y
			#### f'(x): $dy
			#### f''(x): $d2y
			#
			my $g = $dy/$y;
			my $h = $g * $g - $d2y/$y;
			my $f = sqrt(($n - 1) * ($n * $h - $g*$g));
			$f = - $f if (abs($g - $f) > abs($g + $f));

			#
			#### g: $g
			#### h: $h
			#### f: $f
			#
			# Divide by the largest value of $g plus
			# $f, bearing in mind that $f is the result
			# of a square root function and may be positive
			# or negative.
			#
			# Use the abs() function to determine size
			# since $g or $f may be complex numbers.
			#
			my $dx = $n/($g + $f);

			$x -= $dx;
			if (abs($dx) <= $tolerance{laguerre})
			{
				push @roots, $x;
				last ROOT;
			}

			croak "Too many iterations ($its) at dx=$dx\n" if ($its >= $iteration{laguerre});
			$its++;
		}

		### root found at iteration $its
		#### $x
	}

	return @roots;
}


=head3 newtonraphson()

Like L</laguerre()>, a numerical method for finding a root of an equation.

    @roots = newtonraphson(\@coefficients, \@xvalues);
    push @roots, newtonraphson(\@coefficients, $another_xvalue);

For each x value the function will attempt to find a root closest to it.
The function will return real roots only.

This function is provided as an alternative to laguerre(). It is not
used internally by any other functions.

=cut

sub newtonraphson
{
	no Math::Complex;
	my($p_ref, $xval_ref) = @_;
	my $n = $#$p_ref;
	my @xvalues;
	my @roots;

	$p_ref = [reverse @$p_ref] unless ($ascending_flag);

	#
	# Allow some flexibility in sending the x-values.
	#
	if (ref $xval_ref eq "ARRAY")
	{
		@xvalues = @$xval_ref;
	}
	else
	{
		#
		# It could happen. Someone might type \$x instead of $x.
		#
		@xvalues = ((ref $xval_ref eq "SCALAR")? $$xval_ref: $xval_ref);
	}

	#
	### newtonraphson()
	#### @xvalues
	#
	for my $x (@xvalues)
	{
		my $its = 0;

		ROOT:
		for (;;)
		{
			#
			# Get the values of the function and its
			# first derivative at X.
			#
			my($y, $dy, undef) = pl_dxevaluate($p_ref, $x);
			my $dx = $y/$dy;
			$x -= $dx;

			if (abs($dx) <= $tolerance{newtonraphson})
			{
				push @roots, $x;
				last ROOT;
			}

			#
			#### At Iteration: $its
			#### x: $x
			#### f(x): $y
			#### f'(x): $dy
			#
			croak "Too many iterations ($its) at dx=$dx\n" if ($its >= $iteration{newtonraphson});
			$its++;
		}

		### root found at iteration $its
		#### $x
	}

	return @roots;
}

=head3 poly_iteration()

Sets the limit to the number of iterations that a solving method may go
through before giving up trying to find a root. Each method of root-finding
used by L</poly_roots()>, L</sturm_bisection_roots()>, and L</laguerre()>
has its own iteration limit, which may be found, like L</poly_option()>,
simply by looking at the return value of poly_iteration().

    #
    # Get all of the current iteration limits.
    #
    my %its_limits = poly_iteration();

    #
    # Double the limit for the hessenberg method, but set the limit
    # for Laguerre's method to 20.
    #
    my %old_limits = poly_iteration(hessenberg => $its_limits{hessenberg} * 2,
                        laguerre => 20);

    #
    # Reset the limits with the former values, but save the values we had
    # for later.
    #
    my %hl_limits = poly_iteration(%old_limits);

There are iteration limit values for:

=over 4

=item 'hessenberg'

The numeric method used by poly_roots(), if the hessenberg option is set.
Its default value is 60.

=item 'laguerre'

The numeric method used by L</laguerre()>. Laguerre's method is used within
sturm_bisection_roots() once it has narrowed its search in on an individual
root, and of course laguerre() may be called independently. Its default value
is 60.

=item 'newtonraphson'

The numeric method used by newtonraphson(). The Newton-Raphson method is offered
as an alternative to Laguerre's method.  Its default value is 60.

=item 'sturm_bisection'

The bisection method used to find roots within a range. Its default value
is 100.

=back

=cut

sub poly_iteration
{
	my %limits = @_;
	my %old_limits;

	return %iteration if (scalar @_ == 0);

	for my $k (keys %limits)
	{
		#
		# If this is a real iteration limit, save its old value, then set it.
		#
		if (exists $iteration{$k})
		{
			my $val = abs(int($limits{$k}));
			
			carp "poly_iteration(): Unreasonably small value for $k => $val\n" if ($val < 10);

			$old_limits{$k} = $iteration{$k};
			$iteration{$k} = $val;
		}
		else
		{
			croak "poly_iteration(): unknown key $k.";
		}
	}

	return %old_limits;
}

=head3 poly_tolerance()

Set the degree of accuracy needed for comparisons to be equal or roots
to be found.  Amongst the root finding functions this currently only
affects laguerre() and newtonraphson(), as the Hessenberg matrix method
determines how close it needs to get using a complicated formula based
on L</epsilon()>.

    #
    # Print the tolerances.
    #
    my %tolerances = poly_tolerance();
    print "Default tolerances:\n";
    for my $k (keys %tolerances)
    {
        print "$k => ", $tolerances{$k}, "\n";
    }

    #
    # Quadruple the tolerance for Laguerre's method.
    #
    poly_tolerance(laguerre => 4 * $tolerances{laguerre});

Tolerances may be set for:

=over 4

=item 'laguerre'

The numeric method used by laguerre(). Laguerre's method is used within
sturm_bisection_roots() once an individual root has been found within a
range, and of course it may be called independently.

=item 'newtonraphson'

The numeric method used by newtonraphson(). Newton-Raphson is, like
Laguerre's method, a method for finding a root near the starting X value.

=back

=cut

sub poly_tolerance
{
	my %tols = @_;
	my %old_tols;

	return %tolerance if (scalar @_ == 0);

	for my $k (keys %tols)
	{
		#
		# If this is a real tolerance limit, save its old value, then set it.
		#
		if (exists $tolerance{$k})
		{
			my $val = abs($tols{$k});

			$old_tols{$k} = $tolerance{$k};
			$tolerance{$k} = $val;
		}
		else
		{
			croak "poly_tolerance(): unknown key $k.";
		}
	}

	return %old_tols;
}

=head3 poly_nonzero_term_count()

Returns a simple count of the number of coefficients that aren't zero.

=cut

sub poly_nonzero_term_count
{
	my(@coefficients) = @_;
	my $nzc = 0;

	for my $j (0..$#coefficients)
	{
		$nzc++ if (abs($coefficients[$j]) > $epsilon);
	}
	return $nzc;
}

END {
	#unless ($ascending_order_called)
	#{
	#	warn "Ascending order is in default state.\n",
	#	"Please use ascending_order() to make sure your function\n",
	#	"calls will be in the correct order when version 3.00 is installed.\n";
	#warn "Please see Math::Polynomial::Solve documentation.\n" if ($w == 1);
	#}
}

1;
__END__

=pod

=encoding UTF-8

=head1 ACKNOWLEDGMENTS

=head2 The cubic

The cubic is solved by the method described by R. W. D. Nickalls, "A New
Approach to solving the cubic: Cardan's solution revealed," The
Mathematical Gazette, 77, 354-359, 1993.

Dr. Nickalls was kind enough to send me his article, with notes and
revisions, and directed me to a Matlab script that was based on that
article, written by Herman Bruyninckx, of the Dept. Mechanical Eng.,
Div. PMA, Katholieke Universiteit Leuven, Belgium. This function is an
almost direct translation of that script, and I owe Herman Bruyninckx
for creating it in the first place. 

Beginning with version 2.51, Dr. Nikalls's paper is included in the references
directory of this package. Dr. Nickalls has also made his paper available at
L<http://www.nickalls.org/dick/papers/maths/cubic1993.pdf>.

This article is also available on L<http://www.2dcurves.com/cubic/cubic.html>,
and there is a nice discussion of his method at
L<http://www.sosmath.com/algebra/factor/fac111/fac111.html>.

Dick Nickalls, dick@nickalls.org

Herman Bruyninckx, Herman.Bruyninckx@mech.kuleuven.ac.be,
has web page at L<http://www.mech.kuleuven.ac.be/~bruyninc>.
His matlab cubic solver is at
L<http://people.mech.kuleuven.ac.be/~bruyninc/matlab/cubic.m>.

Andy Stein has written a version of cubic.m that will work with
vectors.  It is included with this package in the C<eg> directory.

=head2 The quartic

The method for quartic solution is Ferrari's, as described in the web
page Karl's Calculus Tutor at L<http://www.karlscalculus.org/quartic.html>.
I also made use of some short cuts mentioned in web page Ask Dr. Math FAQ,
at L<http://forum.swarthmore.edu/dr.math/faq/faq.cubic.equations.html>.

=head2 Quintic and higher.

Back when this module could only solve polynomials of degrees 1 through 4,
Matz Kindahl, the original author of Math::Polynomial, suggested the
C<poly_roots()> function. Later on, Nick Ing-Simmons, who was working on a
perl binding to the GNU Scientific Library, sent a perl translation of Hiroshi
Murakami's Fortran implementation of the QR Hessenberg algorithm, and it
fit very well into the C<poly_roots()> function. Quintics and higher degree
polynomials can now be solved, albeit through numeric analysis methods.

Hiroshi Murakami's Fortran routines were at
L<http://netlib.bell-labs.com/netlib/>, but do not seem to be available
from that source anymore. However, his files have been located and are now
included in the C<references/qralg> directory.

He referenced the following articles:

=over 3

=item

R. S. Martin, G. Peters and J. H. Wilkinson, "The QR Algorithm for Real Hessenberg
Matrices", Numer. Math. 14, 219-231(1970).

=item

B. N. Parlett and C. Reinsch, "Balancing a Matrix for Calculation of Eigenvalues
and Eigenvectors", Numer. Math. 13, 293-304(1969).

Fortran code for this routine is at L<http://netlib.sandia.gov/eispack/balanc.f>, and is the basis for L</balance_matrix()>.

=item

Alan Edelman and H. Murakami, "Polynomial Roots from Companion Matrix
Eigenvalues", Math. Comp., v64,#210, pp.763-776(1995).

=back

=head2 Sturm's Sequence and Laguerre's Method

=over 3

=item

DE<0xf6>rrie, Heinrich. I<100 Great Problems of Elementary Mathematics; Their History and Solution>.
New York: Dover Publications, 1965. Translated by David Antin.

Discusses Charles Sturm's 1829 paper with an eye towards mathematical proof
rather than an algorithm, but is still very useful.

=item

Glassner, Andrew S. I<Graphics Gems>. Boston: Academic Press, 1990. 

The chapter "Using Sturm Sequences to Bracket Real Roots
of Polynomial Equations" (by D. G. Hook and P. R. McAree) has a clearer
description of the actual steps needed to implement Sturm's method.

=item

Acton, Forman S. I<Numerical Methods That Work>. New York: Harper & Row, Publishers, 1970.

Lively, opinionated book on numerical equation solving. I looked it up when it
became obvious that everyone was quoting Acton when discussing Laguerre's
method.

=back

=head2 Newton-Raphson

Commonly known as Newton's method. Almost every introduction to calculus
text book will have a section on it; a Wikipedia article is at
L<http://en.wikipedia.org/wiki/Newton%27s_method>.

=head1 SEE ALSO

=over 3

=item

Forsythe, George E., Michael A. Malcolm, and Cleve B. Moler
I<Computer Methods for Mathematical Computations>. Prentice-Hall, 1977.

=item

William Press, Brian P. Flannery, Saul A. Teukolsky, and William T. Vetterling
I<Numerical Recipes in C>.  Cambridge University Press, 1988.  L<http://www.nr.com/>.

=back

=head1 AUTHOR

John M. Gamble may be found at B<jgamble@cpan.org>

=cut

