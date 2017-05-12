# functions for calculating derivatives of data
# $Id: Derivative.pm,v 1.1 1995/12/26 16:26:59 willijar Exp $
=head1 NAME

 Math::Derivative - Numeric 1st and 2nd order differentiation

=head1 SYNOPSIS

    use Math::Derivative qw(Derivative1 Derivative2);

    @dydx = Derivative1(\@x, \@y);
    @d2ydx2 = Derivative2(\@x, \@y);
    @d2ydx2 = Derivative2(\@x, \@y, $yp0, $ypn);

=head1 DESCRIPTION

This Perl package exports functions for performing numerical first
(B<Derivative1>) and second B<Derivative2>) order differentiation on
vectors of data.

=head2 FUNCTIONS

The functions must be imported by name.

=head3 Derivative1()

Take the references to two arrays containing the x and y ordinates of
the data, and return an array of the 1st derivative at the given x ordinates.

=head3 Derivative2()

Take references to two arrays containing the x and y ordinates of the
data and return an array of the 2nd derivative at the given x ordinates.

You may optionally give values to use as the first dervivatives at the
start and end points of the data. If you don't, first derivative values
will be calculated from the arrays for you.

=head1 AUTHOR

John A.R. Williams B<J.A.R.Williams@aston.ac.uk>
John M. Gamble B<jgamble@cpan.org> (current maintainer)

=cut

package Math::Derivative;

use 5.8.3;
use Exporter;
our(@ISA, @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(Derivative1 Derivative2);

our $VERSION = 0.04;

use strict;
use warnings;
use Carp;

sub Derivative1
{
    my ($x, $y) = @_;
    my @y2;
    my $n = $#{$x};

    croak "X and Y array lengths don't match." unless ($n == $#{$y});

    $y2[0] = ($y->[1] - $y->[0])/($x->[1] - $x->[0]);
    $y2[$n] = ($y->[$n] - $y->[$n-1])/($x->[$n] - $x->[$n-1]);

    for (my $i=1; $i<$n; $i++)
    {
	$y2[$i] = ($y->[$i+1] - $y->[$i-1])/($x->[$i+1] - $x->[$i-1]);
    }

    return @y2;
}

sub Derivative2
{
    my ($x, $y, $yp1, $ypn) = @_;
    my $n = $#{$x};
    my (@y2, @u);
    my ($qn, $un);

    croak "X and Y array lengths don't match." unless ($n == $#{$y});

    if (defined $yp1)
    {
	$y2[0] = -0.5;
	$u[0] = (3/($x->[1] - $x->[0])) * (($y->[1] - $y->[0])/($x->[1] - $x->[0]) - $yp1);
    }
    else
    {
	$y2[0] = 0;
        $u[0] = 0;
    }

    for (my $i = 1; $i < $n; $i++)
    {
	my $sig = ($x->[$i] - $x->[$i-1])/($x->[$i+1] - $x->[$i-1]);
	my $p = $sig * $y2[$i-1] + 2.0; 

	$y2[$i] = ($sig - 1.0)/$p;
	$u[$i] = (6.0 * ( ($y->[$i+1] - $y->[$i])/($x->[$i+1] - $x->[$i]) -
		      ($y->[$i] - $y->[$i-1])/($x->[$i] - $x->[$i-1])
		     )/
		($x->[$i+1] - $x->[$i-1]) - $sig * $u[$i-1])/$p;
    }

    if (defined $ypn)
    {
	$qn = 0.5;
	$un = (3.0/($x->[$n]-$x->[$n-1])) *
	    ($ypn - ($y->[$n] - $y->[$n-1])/($x->[$n] - $x->[$n-1]));
    }
    else
    {
	$qn = 0;
	$un = 0;
    }

    $y2[$n] = ($un - $qn * $u[$n-1])/($qn * $y2[$n-1] + 1.0);

    for(my $i = $n-1; $i >= 0; --$i)
    {
	$y2[$i] = $y2[$i] * $y2[$i+1] + $u[$i];
    }

    return @y2;
}

1;
