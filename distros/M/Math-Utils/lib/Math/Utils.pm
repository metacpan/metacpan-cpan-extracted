package Math::Utils;

use 5.010001;
use strict;
use warnings;
use Carp;

use Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
	compare => [ qw(generate_fltcmp generate_relational) ],
	fortran => [ qw(log10 copysign) ],
	utility => [ qw(log10 log2 copysign flipsign
			sign floor ceil fsum
			gcd hcf lcm moduli softmax
			uniform_scaling uniform_01scaling) ],
	polynomial => [ qw(pl_evaluate pl_dxevaluate pl_translate
			pl_add pl_sub pl_div pl_mult
			pl_derivative pl_antiderivative) ],
);

our @EXPORT_OK = (
	@{ $EXPORT_TAGS{compare} },
	@{ $EXPORT_TAGS{utility} },
	@{ $EXPORT_TAGS{polynomial} },
);

#
# Add an :all tag automatically.
#
$EXPORT_TAGS{all} = [@EXPORT_OK];

our $VERSION = '1.14';

=head1 NAME

Math::Utils - Useful mathematical functions not in Perl.

=head1 SYNOPSIS

    use Math::Utils qw(:utility);    # Useful functions

    #
    # Base 10 and base 2 logarithms.
    #
    $scale = log10($pagewidth);
    $bits = log2(1/$probability);

    #
    # Two uses of sign().
    #
    $d = sign($z - $w);

    @ternaries = sign(@coefficients);

    #
    # Using copysign(), $dist will be doubled negative or
    # positive $offest, depending upon whether ($from - $to)
    # is positive or negative.
    #
    my $dist = copysign(2 * $offset, $from - $to);

    #
    # Change increment direction if goal is negative.
    #
    $incr = flipsign($incr, $goal);

    #
    # floor() and ceil() functions.
    #
    $point = floor($goal);
    $limit = ceil($goal);

    #
    # gcd() and lcm() functions.
    #
    $divisor = gcd(@multipliers);
    $numerator = lcm(@multipliers);

    #
    # Safer summation.
    #
    $tot = fsum(@inputs);

    #
    # The remainders of n after successive divisions of b, or
    # remainders after a set of divisions.
    #
    @rems = moduli($n, $b);

or

    use Math::Utils qw(:compare);    # Make comparison functions with tolerance.

    #
    # Floating point comparison function.
    #
    my $fltcmp = generate_fltmcp(1.0e-7);

    if (&$fltcmp($x0, $x1) < 0)
    {
        add_left($data);
    }
    else
    {
        add_right($data);
    }

    #
    # Or we can create single-operation comparison functions.
    #
    # Here we are only interested in the greater than and less than
    # comparison functions.
    #
    my(undef, undef,
        $approx_gt, undef, $approx_lt) = generate_relational(1.5e-5);

or

    use Math::Utils qw(:polynomial);    # Basic polynomial ops

    #
    # Coefficient lists run from 0th degree upward, left to right.
    #
    my @c1 = (1, 3, 5, 7, 11, 13, 17, 19);
    my @c2 = (1, 3, 1, 7);
    my @c3 = (1, -1, 1)

    my $c_ref = pl_mult(\@c1, \@c2);
    $c_ref = pl_add($c_ref, \@c3);

=head1 EXPORT

All functions can be exported by name, or by using the tag that they're
grouped under.

=cut

=head2 utility tag

Useful, general-purpose functions, including those that originated in
FORTRAN and were implemented in Perl in the module L<Math::Fortran>,
by J. A. R. Williams.

There is a name change -- copysign() was known as sign()
in Math::Fortran.

=head3 log10()

    $xlog10 = log10($x);
    @xlog10 = log10(@x);

Return the log base ten of the argument. A list form of the function
is also provided.

=cut

sub log10
{
	my $log10 = log(10);
	return wantarray? map(log($_)/$log10, @_): log($_[0])/$log10;
}

=head3 log2()

    $xlog2 = log2($x);
    @xlog2 = log2(@x);

Return the log base two of the argument. A list form of the function
is also provided.

=cut

sub log2
{
	my $log2 = log(2);
	return wantarray? map(log($_)/$log2, @_): log($_[0])/$log2;
}

=head3 sign()

    $s = sign($x);
    @valsigns = sign(@values);

Returns -1 if the argument is negative, 0 if the argument is zero, and 1
if the argument is positive.

In list form it applies the same operation to each member of the list.

=cut

sub sign
{
	return wantarray? map{($_ < 0)? -1: (($_ > 0)? 1: 0)} @_:
		($_[0] < 0)? -1: (($_[0] > 0)? 1: 0);
}

=head3 copysign()

    $ms = copysign($m, $n);
    $s = copysign($x);

Take the sign of the second argument and apply it to the first. Zero
is considered part of the positive signs.

    copysign(-5, 0);  # Returns 5.
    copysign(-5, 7);  # Returns 5.
    copysign(-5, -7); # Returns -5.
    copysign(5, -7);  # Returns -5.

If there is only one argument, return -1 if the argument is negative,
otherwise return 1. For example, copysign(1, -4) and copysign(-4) both
return -1.

=cut

sub copysign
{
	return ($_[1] < 0)? -abs($_[0]): abs($_[0]) if (@_ == 2);
	return ($_[0] < 0)? -1: 1;
}

=head3 flipsign()

    $ms = flipsign($m, $n);

Multiply the signs of the arguments and apply it to the first. As
with copysign(), zero is considered part of the positive signs.

Effectively this means change the sign of the first argument if
the second argument is negative.

    flipsign(-5, 0);  # Returns -5.
    flipsign(-5, 7);  # Returns -5.
    flipsign(-5, -7); # Returns 5.
    flipsign(5, -7);  # Returns -5.

If for some reason flipsign() is called with a single argument,
that argument is returned unchanged.

=cut

sub flipsign
{
	return -$_[0] if (@_ == 2 and $_[1] < 0);
	return $_[0];
}

=head3 floor()

    $b = floor($a/2);

    @ilist = floor(@numbers);

Returns the greatest integer less than or equal to its argument.
A list form of the function also exists.

    floor(1.5, 1.87, 1);        # Returns (1, 1, 1)
    floor(-1.5, -1.87, -1);     # Returns (-2, -2, -1)

=cut

sub floor
{
	return wantarray? map(($_ < 0 and int($_) != $_)? int($_ - 1): int($_), @_):
		($_[0] < 0 and int($_[0]) != $_[0])? int($_[0] - 1): int($_[0]);
}

=head3 ceil()

    $b = ceil($a/2);

    @ilist = ceil(@numbers);

Returns the lowest integer greater than or equal to its argument.
A list form of the function also exists.

    ceil(1.5, 1.87, 1);        # Returns (2, 2, 1)
    ceil(-1.5, -1.87, -1);     # Returns (-1, -1, -1)

=cut

sub ceil
{
	return wantarray? map(($_ > 0 and int($_) != $_)? int($_ + 1): int($_), @_):
		($_[0] > 0 and int($_[0]) != $_[0])? int($_[0] + 1): int($_[0]);
}

=head3 fsum()

Return a sum of the values in the list, done in a manner to avoid rounding
and cancellation errors. Currently this is done via
L<Kahan's summation algorithm|https://en.wikipedia.org/wiki/Kahan_summation_algorithm>.

=cut

sub fsum
{
	my($sum, $c) = (0, 0);

	for my $v (@_)
	{
		my $y = $v - $c;
		my $t = $sum + $y;

		#
		# If we lost low-order bits of $y (usually because
		# $sum is much larger than $y), save them in $c
		# for the next loop iteration.
		#
		$c = ($t - $sum) - $y;
		$sum = $t;
	}

	return $sum;
}

=head3 softmax()

Return a list of values as probabilities.

The function takes the list, and creates a new list by raising I<e> to
each value. The function then returns each value divided by the sum of
the list. Each value in the new list is now a set of probabilities that
sum to 1.0.

The summation is performed using I<fsum()> above.

See L<Softmax function|https://en.wikipedia.org/wiki/Softmax_function> at
Wikipedia.

=cut

sub softmax
{
	my @nlist = @_;

	#
	# There's a nice trick where you find the maximum value in
	# the list, and subtract it from every number in the list.
	# This renders everything zero or negative, which makes
	# exponentation safe from overflow, but doesn't affect
	# the end result.
	#
	# If we weren't using this trick, then we'd start with
	# the 'my @explist' line, feeding it '@_' instead.
	#
	my $listmax = $nlist[0];
	for (@nlist[1 .. $#nlist])
	{
		$listmax = $_ if ($_ > $listmax);
	}
	@nlist = map{$_ - $listmax} @nlist if ($listmax > 0);

	my @explist = map{exp($_)} @nlist;
	my $sum = fsum(@explist);
	return map{$_/$sum} @explist;
}

=head3 uniform_scaling

=head3 uniform_01scaling

Uniformly, or linearly, scale a number either from one range to another range
(C<uniform_scaling()>), or to a default range of [0 .. 1]
(C<uniform_01scaling()>).

    @v = uniform_scaling(\@original_range, \@new_range, @oldvalues);

For example, these two lines are equivalent, and both return 0:

    $y = uniform_scaling([50, 100], [0, 1], 50);

    $y = uniform_01scaling([50, 100], 50);

They may also be called with a list or array of numbers:

    @cm_measures = uniform_scaling([0, 10000], [0, 25400], @in_measures);

    @melt_centigrade = uniform_scaling([0, 2000], [-273.15, 1726.85], \@melting_points);

A number that is outside the original bounds will be proportionally changed
to be outside of the new bounds, but then again having a number outside the
original bounds is probably an error that should be checked before calling
this function.

L<https://stats.stackexchange.com/q/281164>

=cut

sub uniform_scaling
{
	my @fromrange = @{$_[0]};
	my @torange = @{$_[1]};

	#
	# The remaining parameters are the numbers to rescale.
	#
	# It could happen. Someone might type \$x instead of $x.
	#
	my @xvalues = map{(ref $_ eq "ARRAY")? @$_:
			((ref $_ eq "SCALAR")? $$_: $_)} @_[2 .. $#_];

	return map{($_ - $fromrange[0])/($fromrange[1] - $fromrange[0]) * ($torange[1] - $torange[0]) + $torange[0]} @xvalues;
}

sub uniform_01scaling
{
	my @fromrange = @{$_[0]};

	#
	# The remaining parameters are the numbers to rescale.
	#
	# It could happen. Someone might type \$x instead of $x.
	#
	my @xvalues = map{(ref $_ eq "ARRAY")? @$_:
			((ref $_ eq "SCALAR")? $$_: $_)} @_[1 .. $#_];

	return map{($_ - $fromrange[0]) / ($fromrange[1] - $fromrange[0])} @xvalues;
}

=head3 gcd

=head3 hcf

Return the greatest common divisor (also known as the highest
common factor) of a list of integers. These are simply synomyms:

    $factor = gcd(@numbers);
    $factor = hcf(@numbers);

=cut

sub gcd
{
	use integer;
	my($x, $y, $r);

	#
	# It could happen. Someone might type \$x instead of $x.
	#
	my @values = map{(ref $_ eq "ARRAY")? @$_:
			((ref $_ eq "SCALAR")? $$_: $_)} grep {$_} @_;

	return 0 if (scalar @values == 0);

	$y = abs pop @values;
	$x = abs pop @values;

	while (1)
	{
		($x, $y) = ($y, $x) if ($y < $x);

		$r = $y % $x;
		$y = $x;

		if ($r == 0)
		{
			return $x if (scalar @values == 0);
			$r = abs pop @values;
		}

		$x = $r;
	}

	return $y;
}

#
#sub bgcd
#{
#	my($x, $y) = map(abs($_), @_);
#
#	return $y if ($x == 0);
#	return $x if ($y == 0);
#
#	my $lsbx = low_set_bit($x);
#	my $lsby = low_set_bit($y);
#	$x >>= $lsbx;
#	$y >>= $lsby;
#
#	while ($x != $y)
#	{
#		($x, $y) = ($y, $x) if ($x > $y);
#
#		$y -= $x;
#		$y >>= low_set_bit($y);
#	}
#	return ($x << (($lsbx > $lsby)? $lsby: $lsbx));
#}

*hcf = \&gcd;

=head3 lcm

Return the least common multiple of a list of integers.

    $factor = lcm(@values);

=cut

sub lcm
{
	#
	# It could happen. Someone might type \$x instead of $x.
	#
	my @values = map{(ref $_ eq "ARRAY")? @$_:
			((ref $_ eq "SCALAR")? $$_: $_)} @_;

	my $x = pop @values;

	for my $m (@values)
	{
		$x *= $m/gcd($m, $x);
	}

	return abs $x;
}

=head3 moduli()

Return the moduli of an integer after repeated divisions. The remainders are
returned in a list from left to right.

    @digits = moduli(1899, 10);   # Returns (9, 9, 8, 1)
    @rems = moduli(29, 3);        # Returns (2, 0, 0, 1)

=cut

sub moduli
{
	my($n, $b) = (abs($_[0]), abs($_[1]));
	my @mlist;
	use integer;

	for (;;)
	{
		push @mlist, $n % $b;
		$n /= $b;
		return @mlist if ($n == 0);
	}
	return ();
}

=head2 compare tag

Create comparison functions for floating point (non-integer) numbers.

Since exact comparisons of floating point numbers tend to be iffy,
the comparison functions use a tolerance chosen by you. You may
then use those functions from then on confident that comparisons
will be consistent.

If you do not provide a tolerance, a default tolerance of 1.49012e-8
(approximately the square root of an Intel Pentium's
L<machine epsilon|https://en.wikipedia.org/wiki/Machine_epsilon>)
will be used.

=head3 generate_fltcmp()

Returns a comparison function that will compare values using a tolerance
that you supply. The generated function will return -1 if the first
argument compares as less than the second, 0 if the two arguments
compare as equal, and 1 if the first argument compares as greater than
the second.

    my $fltcmp = generate_fltcmp(1.5e-7);

    my(@xpos) = grep {&$fltcmp($_, 0) == 1} @xvals;

=cut

my $default_tolerance = 1.49012e-8;

sub generate_fltcmp
{
	my $tol = $_[0] // $default_tolerance;

	return sub {
		my($x, $y) = @_;
		return 0 if (abs($x - $y) <= $tol);
		return -1 if ($x < $y);
		return 1;
	}
}

=head3 generate_relational()

Returns a list of comparison functions that will compare values using a
tolerance that you supply. The generated functions will be the equivalent
of the equal, not equal, greater than, greater than or equal, less than,
and less than or equal operators.

    my($eq, $ne, $gt, $ge, $lt, $le) = generate_relational(1.5e-7);

    my(@approx_5) = grep {&$eq($_, 5)} @xvals;

Of course, if you were only interested in not equal, you could use:

    my(undef, $ne) = generate_relational(1.5e-7);

    my(@not_around5) = grep {&$ne($_, 5)} @xvals;

=cut

sub generate_relational
{
	my $tol = $_[0] // $default_tolerance;

	#
	# In order: eq, ne, gt, ge, lt, le.
	#
	return (
		sub {return (abs($_[0] - $_[1]) <= $tol)? 1: 0;},	# eq
		sub {return (abs($_[0] - $_[1]) >  $tol)? 1: 0;},	# ne

		sub {return ((abs($_[0] - $_[1]) > $tol) and ($_[0] > $_[1]))? 1: 0;},	# gt
		sub {return ((abs($_[0] - $_[1]) <= $tol) or ($_[0] > $_[1]))? 1: 0;},	# ge

		sub {return ((abs($_[0] - $_[1]) > $tol) and ($_[0] < $_[1]))? 1: 0;},	# lt
		sub {return ((abs($_[0] - $_[1]) <= $tol) or ($_[0] < $_[1]))? 1: 0;}	# le
	);
}

=head2 polynomial tag

Perform some polynomial operations on plain lists of coefficients.

    #
    # The coefficient lists are presumed to go from low order to high:
    #
    @coefficients = (1, 2, 4, 8);    # 1 + 2x + 4x**2 + 8x**3

In all functions the coeffcient list is passed by reference to the function,
and the functions that return coefficients all return references to a
coefficient list.

B<It is assumed that any leading zeros in the coefficient lists have
already been removed before calling these functions, and that any leading
zeros found in the returned lists will be handled by the caller.> This caveat
is particularly important to note in the case of C<pl_div()>.

Although these functions are convenient for simple polynomial operations,
for more advanced polynonial operations L<Math::Polynomial> is recommended.

=head3 pl_evaluate()

Returns either a y-value for a corresponding x-value, or a list of
y-values on the polynomial for a corresponding list of x-values,
using Horner's method.

    $y = pl_evaluate(\@coefficients, $x);
    @yvalues = pl_evaluate(\@coefficients, @xvalues);

    @ctemperatures = pl_evaluate([-160/9, 5/9], @ftemperatures);

The list of X values may also include X array references:

    @yvalues = pl_evaluate(\@coefficients, @xvalues, \@primes, $x, [-1, -10, -100]);

=cut

sub pl_evaluate
{
	my @coefficients = @{$_[0]};

	#
	# It could happen. Someone might type \$x instead of $x.
	#
	my @xvalues = map{(ref $_ eq "ARRAY")? @$_:
			((ref $_ eq "SCALAR")? $$_: $_)} @_[1 .. $#_];

	#
	# Move the leading coefficient off the polynomial list
	# and use it as our starting value(s).
	#
	my @results = (pop @coefficients) x scalar @xvalues;

	for my $c (reverse @coefficients)
	{
		for my $j (0..$#xvalues)
		{
			$results[$j] = $results[$j] * $xvalues[$j] + $c;
		}
	}

	return wantarray? @results: $results[0];
}

=head3 pl_dxevaluate()

    ($y, $dy, $ddy) = pl_dxevaluate(\@coefficients, $x);

Returns p(x), p'(x), and p"(x) of the polynomial for an
x-value, using Horner's method. Note that unlike C<pl_evaluate()>
above, the function can only use one x-value.

If the polynomial is a linear equation, the second derivative value
will be zero.  Similarly, if the polynomial is a simple constant,
the first derivative value will be zero.

=cut

sub pl_dxevaluate
{
	my($coef_ref, $x) = @_;
	my(@coefficients) = @$coef_ref;
	my $n = $#coefficients;
	my $val = pop @coefficients;
	my $d1val = $val * $n;
	my $d2val = 0;

	#
	# Special case for the linear eq'n (the y = constant eq'n
	# takes care of itself).
	#
	if ($n == 1)
	{
		$val = $val * $x + $coefficients[0];
	}
	elsif ($n >= 2)
	{
		my $lastn = --$n;
		$d2val = $d1val * $n;

		#
		# Loop through the coefficients, except for
		# the linear and constant terms.
		#
		for my $c (reverse @coefficients[2..$lastn])
		{
			$val = $val * $x + $c;
			$d1val = $d1val * $x + ($c *= $n--);
			$d2val = $d2val * $x + ($c * $n);
		}

		#
		# Handle the last two coefficients.
		#
		$d1val = $d1val * $x + $coefficients[1];
		$val = ($val * $x + $coefficients[1]) * $x + $coefficients[0];
	}

	return ($val, $d1val, $d2val);
}

=head3 pl_translate()

    $x = [8, 3, 1];
    $y = [3, 1];

    #
    # Translating C<x**2 + 3*x + 8> by C<x + 3> returns [26, 9, 1]
    #
    $z = pl_translate($x, $y);

Returns a polynomial transformed by substituting a polynomial variable with another polynomial.
For example, a simple linear translation by 1 to the polynomial C<x**3 + x**2 + 4*x + 4>
would be accomplished by setting x = (y - 1); resulting in C<x**3 - 2*x**2 + 5*x>.

    $x = [4, 4, 1, 1];
    $y = [-1, 1];
    $z = pl_translate($x, $y);         # Becomes [0, 5, -2, 1]

=cut

sub pl_translate
{
	my($x, $y) = @_;

	my @x_arr = @$x;
	my @z = pop @x_arr;

	for my $c (reverse @x_arr)
	{
		@z = @{ pl_mult(\@z, $y) };
		$z[0] += $c;
	}

	return [@z];
}

=head3 pl_add()

    $polyn_ref = pl_add(\@m, \@n);

Add two lists of numbers as though they were polynomial coefficients.

=cut

sub pl_add
{
	my(@av) = @{$_[0]};
	my(@bv) = @{$_[1]};
	my $ldiff = scalar @av - scalar @bv;

	my @result = ($ldiff < 0)?
		splice(@bv, scalar @bv + $ldiff, -$ldiff):
		splice(@av, scalar @av - $ldiff, $ldiff);

	unshift @result, map($av[$_] + $bv[$_], 0.. $#av);

	return \@result;
}

=head3 pl_sub()

    $polyn_ref = pl_sub(\@m, \@n);

Subtract the second list of numbers from the first as though they
were polynomial coefficients.

=cut

sub pl_sub
{
	my(@av) = @{$_[0]};
	my(@bv) = @{$_[1]};
	my $ldiff = scalar @av - scalar @bv;

	my @result = ($ldiff < 0)?
		map {-$_} splice(@bv, scalar @bv + $ldiff, -$ldiff):
		splice(@av, scalar @av - $ldiff, $ldiff);

	unshift @result, map($av[$_] - $bv[$_], 0.. $#av);

	return \@result;
}

=head3 pl_div()

    ($q_ref, $r_ref) = pl_div(\@numerator, \@divisor);

Synthetic division for polynomials. Divides the first list of coefficients
by the second list.

Returns references to the quotient and the remainder.

Remember to check for leading zeros (which are rightmost in the list) in
the returned values. For example,

    my @n = (4, 12, 9, 3);
    my @d = (1, 3, 3, 1);

    my($q_ref, $r_ref) = pl_div(\@n, \@d);

After division you will have returned C<(3)> as the quotient,
and C<(1, 3, 0)> as the remainder. In general, you will want to remove
the leading zero, or for that matter values within epsilon of zero, in
the remainder.

    my($q_ref, $r_ref) = pl_div($f1, $f2);

    #
    # Remove any leading zeros (i.e., numbers smaller in
    # magnitude than machine epsilon) in the remainder.
    #
    my @remd = @{$r_ref};
    pop @remd while (@remd and abs($remd[$#remd]) < $epsilon);

    $f1 = $f2;
    $f2 = [@remd];

If C<$f1> and C<$f2> were to go through that bit of code again, not
removing the leading zeros would lead to a divide-by-zero error.

If either list of coefficients is empty, pl_div() returns undefs for
both quotient and remainder.

=cut

sub pl_div
{
	my @numerator = @{$_[0]};
	my @divisor = @{$_[1]};

	my @quotient;

	my $n_degree = $#numerator;
	my $d_degree = $#divisor;

	#
	# Sanity checks: a numerator less than the divisor
	# is automatically the remainder; and return a pair
	# of undefs if either set of coefficients are
	# empty lists.
	#
	return ([0], \@numerator) if ($n_degree < $d_degree);
	return (undef, undef) if ($d_degree < 0 or $n_degree < 0);

	my $lead_coefficient = $divisor[$#divisor];

	#
	# Perform the synthetic division. The remainder will
	# be what's left in the numerator.
	# (4, 13, 4, -9, 6) / (1, 2) = (4, 5, -6, 3)
	#
	@quotient = reverse map {
		#
		# Get the next term for the quotient. We pop
		# off the lead numerator term, which would become
		# zero due to subtraction anyway.
		#
		my $q = (pop @numerator)/$lead_coefficient;

		for my $k (0..$d_degree - 1)
		{
			$numerator[$#numerator - $k] -= $q * $divisor[$d_degree - $k - 1];
		}

		$q;
	} reverse (0 .. $n_degree - $d_degree);

	return (\@quotient, \@numerator);
}

=head3 pl_mult()

    $m_ref = pl_mult(\@coefficients1, \@coefficients2);

Returns the reference to the product of the two multiplicands.

=cut

sub pl_mult
{
	my($av, $bv) = @_;
	my $a_degree = $#{$av};
	my $b_degree = $#{$bv};

	#
	# Rather than multiplying left to right for each element,
	# sum to each degree of the resulting polynomial (the list
	# after the map block). Still an O(n**2) operation, but
	# we don't need separate storage variables.
	#
	return [ map {
		my $a_idx = ($a_degree > $_)? $_: $a_degree;
		my $b_to = ($b_degree > $_)? $_: $b_degree;
		my $b_from = $_ - $a_idx;

		my $c = $av->[$a_idx] * $bv->[$b_from];

		for my $b_idx ($b_from+1 .. $b_to)
		{
			$c += $av->[--$a_idx] * $bv->[$b_idx];
		}
		$c;
	} (0 .. $a_degree + $b_degree) ];
}

=head3 pl_derivative()

    $poly_ref = pl_derivative(\@coefficients);

Returns the derivative of a polynomial.

=cut

sub pl_derivative
{
	my @coefficients = @{$_[0]};
	my $degree = $#coefficients;

	return [] if ($degree < 1);

	$coefficients[$_] *= $_ for (2..$degree);

	shift @coefficients;
	return \@coefficients;
}

=head3 pl_antiderivative()

    $poly_ref = pl_antiderivative(\@coefficients);

Returns the antiderivative of a polynomial. The constant value is
always set to zero and will need to be changed by the caller if a
different constant is needed.

  my @coefficients = (1, 2, -3, 2);
  my $integral = pl_antiderivative(\@coefficients);

  #
  # Integral needs to be 0 at x = 1.
  #
  my @coeff1 = @{$integral};
  $coeff1[0] = - pl_evaluate($integral, 1);

=cut

sub pl_antiderivative
{
	my @coefficients = @{$_[0]};
	my $degree = scalar @coefficients;

	#
	# Sanity check if its an empty list.
	#
	return [0] if ($degree < 1);

	$coefficients[$_ - 1] /= $_ for (2..$degree);

	unshift @coefficients, 0;
	return \@coefficients;
}

=head1 AUTHOR

John M. Gamble, C<< <jgamble at cpan.org> >>

=head1 SEE ALSO

L<Math::Polynomial> for a complete set of polynomial operations, with the
added convenience that objects bring.

Among its other functions, L<List::Util> has the mathematically useful
functions max(), min(), product(), sum(), and sum0().

L<List::MoreUtils> has the function minmax().

L<Math::Prime::Util> has gcd() and lcm() functions, as well as vecsum(),
vecprod(), vecmin(), and vecmax(), which are like the L<List::Util>
functions but which can force integer use, and when appropriate use
L<Math::BigInt>.

L<Math::VecStat> Likewise has min(), max(), sum() (which can take
as arguments array references as well as arrays), plus maxabs(),
minabs(), sumbyelement(), convolute(), and other functions.

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-util at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

This module is on Github at L<https://github.com/jgamble/Math-Utils>.

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Utils>

=item * MetaCPAN

L<https://metacpan.org/release/Math-Utils>

=back

=head1 ACKNOWLEDGEMENTS

To J. A. R. Williams who got the ball rolling with L<Math::Fortran>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2017 John M. Gamble. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

1; # End of Math::Utils
