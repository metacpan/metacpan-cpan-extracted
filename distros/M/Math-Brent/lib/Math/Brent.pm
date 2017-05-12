package Math::Brent;

use 5.010001;
use strict;
use warnings;

use Exporter;
our (@ISA, @EXPORT_OK, %EXPORT_TAGS);
@ISA = qw(Exporter);
%EXPORT_TAGS = (
	all => [qw(
		BracketMinimum
		Brent Minimise1D
		Brentzero
	) ],
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{all} } );

our $VERSION = 1.00;

use Math::VecStat qw(max min);
use Math::Utils qw(:fortran);
use Carp;
#use Smart::Comments ('###', '####');  # 3 for variables, 4 for 'here we are'.

=head1 NAME

Math::Brent - Brent's single dimensional function minimisation, and Brent's zero finder.

=head1 SYNOPSIS

    use Math::Brent qw(Minimise1D);

    my $tolerance = 1e-7;
    my $itmax = 80;

    sub sinc {
      my $x = shift ;
      return $x ? sin($x)/$x: 1;
    }

    my($x, $y) = Minimise1D(1, 1, \&sinc, $tolerance, $itmax);

    print "Minimum is at sinc($x) = $y\n";

or

    use Math::Brent qw(BracketMinimum Brent);

    my $tolerance = 1e-7;
    my $itmax = 80;

    #
    # If you want to use the separate functions
    # instead of a single call to Minimise1D().
    #
    my($ax, $bx, $cx, $fa, $fb, $fc) = BracketMinimum($ax, $bx, \&sinc);
    my($x, $y) = Brent($ax, $bx, $cx, \&sinc, $tolerance, $itmax);

    print "Minimum is at sinc($x) = $y\n";

In either case the output will be C<Minimum is at sinc(4.4934094397196) = -.217233628211222>

This module has implementations of Brent's method for one-dimensional
minimisation of a function without using derivatives. This algorithm
cleverly uses both the Golden Section Search and parabolic
interpolation.

Anonymous subroutines may also be used as the function reference:

    my $cubic_ref = sub {my($x) = @_; return 6.25 + $x*$x*(-24 + $x*8));};

    my($x, $y) = Minimise1D(3, 1, $cubic_ref);
    print "Minimum of the cubic at $x = $y\n";

In addition to finding the minimum, there is also an implementation of the
Van Wijngaarden-Dekker-Brent Method, used to find a function's root without
using derivatives.

    use Math::Brent qw(Brentzero);

    my $tolerance = 1e-7;
    my $itmax = 80;

    sub wobble
    {
        my($t) = @_;
        return $t - cos($t);
    }

    #
    # Find the zero somewhere between .5 and 1.
    #
    $r = Brentzero(0.5, 1.0, \&wobble, $tolerance, $itmax);

=head1 EXPORT

Each function can be exported by name, or all may be exported by using the tag 'all'.

=head2 FUNCTIONS

The functions may be imported by name, or by using the export
tag "all".

=cut

=head3 Minimise1D()

Provides a simple interface to the L</BracketMinimum()> and L</Brent()>
routines.

Given a function, an initial guess for the function's
minimum, and its scaling, this routine converges
to the function's minimum using Brent's method.

    ($x, $y) = Minimise1D($guess, $scale, \&func);

The minimum is reached within a certain tolerance (defaulting 1e-7), and
attempts to do so within a maximum number of iterations (defaulting to 100).
You may override them by providing alternate values:

    ($x, $y) = Minimise1D($guess, $scale, \&func, 1.5e-8, 120);

=cut

sub Minimise1D
{
    my ($guess, $scale, $func, $tol, $itmax) = @_;
    my ($a, $b, $c) = BracketMinimum($guess - $scale, $guess + $scale, $func);

    return Brent($a, $b, $c, $func, $tol, $itmax);
}

#
# BracketMinimum
#
# BracketMinimum is MNBRAK minimum bracketing routine from section 10.1
# of Numerical Recipies
#

my $GOLD = 0.5 + sqrt(1.25); # Default magnification ratio for intervals is phi.
my $GLIMIT = 100.0; # Max magnification for parabolic fit step
my $TINY = 1E-20;

=head3 BracketMinimum()

    ($ax, $bx, $cx, $fa, $fb, $fc) = BracketMinimum($ax, $bx);

Given a function reference B<\&func> and distinct initial points B<$ax>
and B<$bx>, this routine searches in the downhill direction and returns
a list of the three points B<$ax>, B<$bx>, B<$cx> which bracket the
minimum of the function, along with the function values at those three
points, $fa, $fb, $fc.

The points B<$ax>, B<$bx>, B<$cx> may then be used in the function Brent().

=cut

sub BracketMinimum
{
    my ($ax, $bx, $func) = @_;
    my ($fa, $fb) = (&$func($ax), &$func($bx));

    #
    # Swap the a and b values if we weren't going in
    # a downhill direction.
    #
    if ($fb > $fa)
    {
	my $t = $ax; $ax = $bx; $bx = $t;
	$t = $fa; $fa = $fb; $fb = $t;
    }

    my $cx = $bx + $GOLD * ($bx - $ax);
    my $fc = &$func($cx);

    #
    # Loop here until we bracket
    #
    while ($fb >= $fc)
    {
	#
	# Compute U by parabolic extrapolation from
	# a, b, c. TINY used to prevent div by zero
	#
	my $r = ($bx - $ax) * ($fb - $fc);
	my $q = ($bx - $cx) * ($fb - $fa);
	my $u = $bx - (($bx - $cx) * $q - ($bx - $ax) * $r)/
	    (2.0 * copysign(max(abs($q - $r), $TINY), $q - $r));

	my $ulim = $bx + $GLIMIT * ($cx - $bx); # We won't go further than this
	my $fu;

	#
	# Parabolic U between B and C - try it.
	#
	if (($bx - $u) * ($u - $cx) > 0.0)
	{
	    $fu = &$func($u);

	    if ($fu < $fc)
	    {
		# Minimum between B and C
		$ax = $bx; $fa = $fb; $bx = $u;  $fb = $fu;
		next;
	    }
	    elsif ($fu > $fb)
	    {
		# Minimum between A and U
		$cx = $u; $fc = $fu;
		next;
	    }

	    $u = $cx + $GOLD * ($cx - $bx);
	    $fu = &$func($u);
	}
	elsif (($cx - $u) * ($u - $ulim) > 0)
	{
	    # parabolic  fit between C and limit
	    $fu = &$func($u);

	    if ($fu < $fc)
	    {
		$bx = $cx; $cx = $u;
		$u = $cx + $GOLD * ($cx - $bx);
		$fb = $fc; $fc = $fu;
		$fu = &$func($u);
	    }
	}
	elsif (($u - $ulim) * ($ulim - $cx) >= 0)
	{
	    # Limit parabolic U to maximum
	    $u = $ulim;
	    $fu = &$func($u);
	}
	else
	{
	    # eject parabolic U, use default magnification
	    $u = $cx + $GOLD * ($cx - $bx);
	    $fu = &$func($u);
	}

	# Eliminate oldest point and continue
	$ax = $bx; $bx = $cx; $cx = $u;
	$fa = $fb; $fb = $fc; $fc = $fu;
    }

    return ($ax, $bx, $cx, $fa, $fb, $fc);
}

#
# The complementary step is (3 - sqrt(5))/2, which resolves to 2 - phi.
#
my $CGOLD = 2 - $GOLD;
my $ZEPS = 1e-10;

=head3 Brent()

Given a function and a triplet of abcissas B<$ax>, B<$bx>, B<$cx>, such that

=over 4

=item 1. B<$bx> is between B<$ax> and B<$cx>, and

=item 2. B<func($bx)> is less than both B<func($ax)> and B<func($cx)>),

=back

Brent() isolates the minimum to a fractional precision of about B<$tol>
using Brent's method.

A maximum number of iterations B<$itmax> may be specified for this search - it
defaults to 100. Returned is a list consisting of the abcissa of the minum
and the function value there.

=cut

sub Brent
{
    my ($ax, $bx, $cx, $func, $tol, $ITMAX) = @_;
    my ($d, $u, $x, $w, $v); # ordinates
    my ($fu, $fx, $fw, $fv); # function evaluations

    $ITMAX //= 100;
    $tol //= 1e-8;

    my $a = min($ax, $cx);
    my $b = max($ax, $cx);

    $x = $w = $v = $bx;
    $fx = $fw = $fv = &$func($x);
    my $e = 0.0; # will be distance moved on the step before last
    my $iter = 0;

    while ($iter < $ITMAX)
    {
	my $xm = 0.5 * ($a + $b);
	my $tol1 = $tol * abs($x) + $ZEPS;
	my $tol2 = 2.0 * $tol1;

	last if (abs($x - $xm) <= ($tol2 - 0.5 * ($b - $a)));

	if (abs($e) > $tol1)
	{
	    my $r = ($x-$w) * ($fx-$fv);
	    my $q = ($x-$v) * ($fx-$fw);
	    my $p = ($x-$v) * $q-($x-$w)*$r;

	    $p = -$p if (($q = 2 * ($q - $r)) > 0.0);

	    $q = abs($q);
	    my $etemp = $e;
	    $e = $d;

	    unless ( (abs($p) >= abs(0.5 * $q * $etemp)) or
		($p <= $q * ($a - $x)) or ($p >= $q * ($b - $x)) )
	    {
                #
	        # Parabolic step OK here - take it.
                #
	        $d = $p/$q;
	        $u = $x + $d;

	        if ( (($u - $a) < $tol2) or (($b - $u) < $tol2) )
	        {
		    $d = copysign($tol1, $xm - $x);
	        }
	        goto dcomp; # Skip the golden section step.
	    }
	}

        #
        # Golden section step.
        #
	$e = (($x >= $xm) ? $a : $b) - $x;
	$d = $CGOLD * $e;

        #
        # We arrive here with d from Golden section or parabolic step.
        #
        dcomp:
	$u = $x + ((abs($d) >= $tol1) ? $d : copysign($tol1, $d));
	$fu = &$func($u); # 1 &$function evaluation per iteration

	#
	# Decide what to do with &$function evaluation
	#
	if ($fu <= $fx)
	{
	    if ($u >= $x)
	    {
                $a = $x;
	    }
	    else
	    {
                $b = $x;
	    }
	    $v = $w; $fv = $fw;
	    $w = $x; $fw = $fx;
	    $x = $u; $fx = $fu;
	}
	else
	{
	    if ($u < $x)
	    {
		    $a = $u;
	    }
	    else
	    {
		    $b = $u;
	    }

	    if ($fu <= $fw or $w == $x)
	    {
		$v = $w; $fv = $fw;
		$w = $u; $fw = $fu;
	    }
	    elsif ( $fu <= $fv or $v == $x or $v == $w )
	    {
		    $v = $u; $fv = $fu;
	    }
	}

	$iter++;
    }

    carp "Brent Exceed Maximum Iterations.\n" if ($iter >= $ITMAX);
    return ($x, $fx);
}

sub Brentzero
{
	my($a, $b, $func, $tol, $ITMAX) = @_;
	my $fa = &$func($a);
	my $fb = &$func($b);

	if (($fa > 0.0 and $fb > 0.0) or ($fa < 0.0 and $fb < 0.0))
	{
		carp "Brentzero(): root was not bracketed by [$a, $b].";
		return undef;
	}

	$ITMAX //= 100;
	$tol //= 1e-8;

	my($c, $fc) = ($b, $fb);
	my($d, $e);
	my $iter = 0;

	while ($iter < $ITMAX)
	{
		#
		# Adjust bounding interval $d.
		#
		### iteration: $iter
		### a: $a
		### b: $b
		### fa: $fa
		### fb: $fb
		### fc: $fc
		#
		if (($fb > 0.0 and $fc > 0.0) or ($fb < 0.0 and $fc < 0.0))
		{
			$fc = $fa;
			$c = $a;
			$d = $b - $a;
			$e = $d;
		}

		if (abs($fc) < abs($fb))
		{
			$a = $b;
			$b = $c;
			$c = $a;
			$fa = $fb;
			$fb = $fc;
			$fc = $fa;
		}

		#
		# Convergence check.
		#
		### a: $a
		### b: $b
		### c: $c
		### d: $d
		### fa: $fa
		### fb: $fb
		### fc: $fc
		#
		my $xm = ($c - $b) * 0.5;
		my $tol1 = 2.0 * $ZEPS * abs($b) + ($tol * 0.5);

		#
		### tol1: $tol1
		### xm: $xm
		#
		return $b if (abs($xm) <= $tol1 or $fb == 0.0);

		if (abs($e) >= $tol1 and abs($fa) > abs($fb))
		{
			#
			# Attempt inverse quadratic interpolation.
			#
			#### Branch (abs(e) >= tol1 and abs(fa) > abs(fb))
			#
			my($p, $q);
			my $s = $fb/$fa;

			if ($a == $c)
			{
				#### Branch (a == c)
				$p = 2.0 * $xm * $s;
				$q = 1.0 - $s;
			}
			else
			{
				#### Branch (a != c)
				my $r = $fb/$fc;
				$q = $fa/$fc;
				$p = $s * (2.0 * $xm * $q * ($q - $r) -
					($b - $a) * ($r - 1.0));
				$q = ($q - 1.0) * ($r - 1.0) * ($s - 1.0);
			}

			#
			# Check if in bounds.
			#
			### q: $q
			### p: $p
			### s: $s
			### e: $e
			#
			$q = - $q if ($p > 0.0);
			$p = abs($p);
			my $min1 = 3.0 * $xm * $q - abs($tol1 * $q);
			my $min2 = abs($e * $q);

			if (2.0 * $p < min($min1, $min2))
			{
				#
				# Interpolation worked, use it.
				#
				#### Branch (2.0 * p < min(min1, min2))
				#
				$e = $d;
				$d = $p/$q;
			}
			else
			{
				#
				# Interpolation failed, use bisection.
				#
				#### Branch (2.0 * p >= min(min1, min2))
				#
				$d = $xm;
				$e = $d;
			}
		}
		else
		{
			#
			# Bounds decreasing too slowly for
			# quadratic interpolation, use bisection.
			#
			$d = $xm;
			$e = $d;
		}

		#
		# Move last best guess to $a.
		#
		$a = $b;
		$fa = $fb;

		#
		# Calculate the next guess.
		#
		$b += (abs($d) > $tol1)? $d: copysign($tol1, $xm);
		$fb = &$func($b);
		$iter++;
	}

	carp "Brentzero Exceed Maximum Iterations.\n" if ($iter >= $ITMAX);
	return $a;
}

1;
__END__

=pod

=head1 BUGS

Please report any bugs or feature requests via Github's
L<issues link|https://github.com/jgamble/Math-Brent/issues>

=head1 AUTHOR

John A.R. Williams B<J.A.R.Williams@aston.ac.uk>

John M. Gamble B<jgamble@cpan.org> (current maintainer)

=head1 SEE ALSO

"Numerical Recipies: The Art of Scientific Computing"
W.H. Press, B.P. Flannery, S.A. Teukolsky, W.T. Vetterling.
Cambridge University Press. ISBN 0 521 30811 9.

Richard P. Brent, L<Algorithms for Minimization Without Derivatives|http://www.worldcat.org/title/algorithms-for-minimization-without-derivatives/oclc/515987&referer=brief_results>

Professor (Emeritus) Richard Brent has a web page at
L<http://maths-people.anu.edu.au/~brent/>

=cut
