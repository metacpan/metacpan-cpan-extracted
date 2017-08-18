package Math::Derivative;

use 5.010001;
use Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = (all => [qw(
	Derivative1
	Derivative2
	centraldiff
	forwarddiff
)]);

our @EXPORT_OK = (@{$EXPORT_TAGS{all}});

our $VERSION = 1.01;

use strict;
use warnings;
use Carp;

=head1 NAME

Math::Derivative - Numeric 1st and 2nd order differentiation

=head1 SYNOPSIS

    use Math::Derivative qw(:all);

    @dydx = forwarddiff(\@x, \@y);

    @dydx = centraldiff(\@x, \@y);

    @dydx = Derivative1(\@x, \@y);     # A synonym for centraldiff()

    @d2ydx2 = Derivative2(\@x, \@y, $yd0, $ydn);

=head1 DESCRIPTION

This Perl package exports functions that numerically approximate first
and second order differentiation on vectors of data. The accuracy of
the approximation will depend upon the differences between the
successive values in the X array.

=head2 FUNCTIONS

The functions may be imported by name or by using the tag ":all".

=head3 forwarddiff()

    @dydx = forwarddiff(\@x, \@y);

Take the references to two arrays containing the x and y ordinates of
the data, and return an array of approximate first derivatives at the
given x ordinates, using the forward difference approximation.

The last term is actually formed using a backward difference formula,
there being no array item to subtract from at the end of the array.
If you want to use derivatives strictly formed from the forward
difference formula, use only the values from [0 .. #y-1], e.g.:

    @dydx = (forwarddiff(\@x, \@y))[0 .. $#y-1];

or, more simply,

    @dydx = forwarddiff(\@x, \@y);
    pop @dydx;

=cut

sub forwarddiff
{
	my($x, $y) = @_;
	my @y2;
	my $n = $#{$x};

	croak "X and Y array lengths don't match." unless ($n == $#{$y});

	$y2[$n] = ($y->[$n] - $y->[$n-1])/($x->[$n] - $x->[$n-1]);

	for my $i (0 .. $n-1)
	{
		$y2[$i] = ($y->[$i+1] - $y->[$i])/($x->[$i+1] - $x->[$i]);
	}

	return @y2;
}

=head3 centraldiff()

    @dydx = centraldiff(\@x, \@y);

Take the references to two arrays containing the x and y ordinates of
the data, and return an array of approximate first derivatives at the
given x ordinates.

The algorithm used three data points to calculate the derivative, except
at the end points, where by necessity the forward difference algorithm
is used instead. If you want to use derivatives strictly formed from
the central difference formula, use only the values from [1 .. #y-1],
e.g.:

    @dydx = (centraldiff(\@x, \@y))[1 .. $#y-1];

=cut

sub centraldiff
{
	my($x, $y) = @_;
	my @y2;
	my $n = $#{$x};

	croak "X and Y array lengths don't match." unless ($n == $#{$y});

	$y2[0] = ($y->[1] - $y->[0])/($x->[1] - $x->[0]);
	$y2[$n] = ($y->[$n] - $y->[$n-1])/($x->[$n] - $x->[$n-1]);

	for my $i (1 .. $n-1)
	{
		$y2[$i] = ($y->[$i+1] - $y->[$i-1])/($x->[$i+1] - $x->[$i-1]);
	}

	return @y2;
}

=head3 Derivative2()

    @d2ydx2 = Derivative2(\@x, \@y);

or

    @d2ydx2 = Derivative2(\@x, \@y, $yp0, $ypn);

Take references to two arrays containing the x and y ordinates of the
data and return an array of approximate second derivatives at the given
x ordinates.

You may optionally give values to use as the first derivatives at the
start and end points of the data. If you don't, first derivative values
will be assumed to be zero.

=cut

sub seconddx
{
	my($x, $y, $yp1, $ypn) = @_;
	my(@y2, @u);
	my $n = $#{$x};

	croak "X and Y array lengths don't match." unless ($n == $#{$y});

	if (defined $yp1)
	{
		$y2[0] = -0.5;
		$u[0] = (3/($x->[1] - $x->[0])) *
			(($y->[1] - $y->[0])/($x->[1] - $x->[0]) - $yp1);
	}
	else
	{
		$y2[0] = 0;
		$u[0] = 0;
	}

	for my $i (1 .. $n-1)
	{
		my $sig = ($x->[$i] - $x->[$i-1])/($x->[$i+1] - $x->[$i-1]);
		my $p = $sig * $y2[$i-1] + 2.0;

		$y2[$i] = ($sig - 1.0)/$p;
		$u[$i] = (6.0 * (
			($y->[$i+1] - $y->[$i])/($x->[$i+1] - $x->[$i]) -
			($y->[$i] - $y->[$i-1])/($x->[$i] - $x->[$i-1]))/
			($x->[$i+1] - $x->[$i-1]) - $sig * $u[$i-1])/$p;
	}

	if (defined $ypn)
	{
		my $qn = 0.5;
		my $un = (3.0/($x->[$n]-$x->[$n-1])) *
			($ypn - ($y->[$n] - $y->[$n-1])/($x->[$n] - $x->[$n-1]));
		$y2[$n] = ($un - $qn * $u[$n-1])/($qn * $y2[$n-1] + 1.0);
	}
	else
	{
		$y2[$n] = 0;
	}

	for my $i (reverse 0 .. $n-1)
	{
		$y2[$i] = $y2[$i] * $y2[$i+1] + $u[$i];
	}

	return @y2;
}

=head3 Derivative1()

A synonym for centraldiff().

=cut

#
# Alias Derivative1() to centraldiff(), and Derivative2() to
# seconddx(), preserving the old names. Not exporting the
# seconddx name now, as I'm not convinced it's a good name.
#
*Derivative1 = \&centraldiff;
*Derivative2 = \&seconddx;

=head1 REFERENCES

L<http://www.holoborodko.com/pavel/numerical-methods/numerical-derivative/central-differences/>

L<http://www.robots.ox.ac.uk/~sjrob/Teaching/EngComp/ecl6.pdf>

=head1 AUTHOR

John A.R. Williams B<J.A.R.Williams@aston.ac.uk>

John M. Gamble B<jgamble@cpan.org> (current maintainer)

=cut

1;
