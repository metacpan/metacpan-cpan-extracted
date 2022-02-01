## Math/MatrixDecomposition/Util.pm --- utility functions.

# Copyright (C) 2010 Ralph Schleicher.  All rights reserved.

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

## Code:

package Math::MatrixDecomposition::Util;

use strict;
use warnings;
use Exporter qw(import);
use POSIX qw(fmod);

BEGIN
{
  our $VERSION = '1.06';
  our @EXPORT_OK = qw(eps isnan mod min max sign hypot cdiv);
  our %EXPORT_TAGS = (all => [@EXPORT_OK]);
}

# Machine precision.
my $epsilon = 1.0;

*eps = sub () { $epsilon; };

INIT
{
  my $tem;

  while (1)
    {
      $tem = 1.0 + $epsilon / 2.0;
      last if $tem == 1.0;
      $epsilon /= 2.0;
    }
}

# Not-a-number.
sub isnan ($)
{
  my $x = shift;

  $x != $x;
}

# Remainder of floating-point division.
*mod = \&fmod;

# Minimum value.
sub min ($$)
{
  my ($a, $b) = @_;

  $a < $b ? $a : $b;
}

# Maximum value.
sub max ($$)
{
  my ($a, $b) = @_;

  $a > $b ? $a : $b;
}

# Transfer sign.
sub sign ($$)
{
  my ($a, $b) = @_;

  ($a < 0) == ($b < 0) ? $a : -$a;
}

# Length of the hypotenuse of a right triangle.
sub hypot ($$)
{
  my $a = abs (shift);
  my $b = abs (shift);

  # Work variables.
  my ($s, $t);

  if ($a >= $b)
    {
      $s = $a;
      # Avoid division by zero.
      $t = ($a == $b ? 1.0 : $b / $a);
    }
  else
    {
      $s = $b;
      $t = $a / $b;
    }

  $s * sqrt (1.0 + $t * $t);
}

# Complex division.
sub cdiv ($$$$)
{
  my ($a_re, $a_im, $b_re, $b_im) = @_;

  # Work variables.
  my ($r, $d, @z);

  if (abs ($b_re) > abs ($b_im))
    {
      $r = $b_im / $b_re;
      $d = $b_re + $r * $b_im;
      @z = (($a_re + $r * $a_im) / $d,
	    ($a_im - $r * $a_re) / $d);
    }
  else
    {
      $r = $b_re / $b_im;
      $d = $b_im + $r * $b_re;
      @z = (($r * $a_re + $a_im) / $d,
	    ($r * $a_im - $a_re) / $d);
    }

  @z;
}

1;

__END__

=pod

=head1 NAME

Math::MatrixDecomposition::Util - utility functions


=head1 SYNOPSIS

    use Math::MatrixDecomposition::Util qw(:all);


=head1 DESCRIPTION

This module contains a colorful collection of utility functions.
Nothing is exported by default.


=head2 Utility Functions

=over

=item C<eps>

Return the machine precision.


=item C<isnan> (I<x>)

Return true if I<x> is not-a-number.


=item C<mod> (I<num>, I<den>)

Return the remainder of a division.  Any argument can be either an
integral number or a floating-point number.


=item C<min> (I<a>, I<b>)

Return the minimum value of the two arguments.


=item C<max> (I<a>, I<b>)

Return the maximum value of the two arguments.


=item C<sign> (I<a>, I<b>)

Return the value of I<a> with the sign of I<b>.

If the second argument I<b> is less than zero, the return value is a
non-positive number.  Otherwise, the return value is a non-negative
number.


=item C<hypot> (I<a>, I<b>)

Return the length of the hypotenuse of a right triangle.  This is equal
to the distance of a point to the origin in a two-dimensional Cartesian
coordinate system.


=item C<cdiv> (I<a_re>, I<a_im>, I<b_re>, I<b_im>)

Return the real part and imaginary part of the division of two complex
numbers.

=back


=head1 AUTHOR

Ralph Schleicher <ralph@cpan.org>

=cut

## Math/MatrixDecomposition/Util.pm ends here
