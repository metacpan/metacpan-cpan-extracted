## Math/BLAS/PP.pm --- basic linear algebra subroutines.

# Copyright (C) 2010 Ralph Schleicher.  All rights reserved.

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

## Code:

package Math::BLAS::PP;

use strict;
use warnings;
use Carp;
use Exporter qw(import);
use POSIX qw(:float_h);

use Math::BLAS::Enum;

BEGIN
{
  our $VERSION = '1.01';
  our @EXPORT = qw(dot_d
		   norm_d
		   sum_d
		   min_val_d
		   amin_val_d
		   max_val_d
		   amax_val_d
		   sumsq_d
		   scale_d
		   rscale_d
		   axpby_d
		   waxpby_d
		   copy_d
		   swap_d
		   gemv_d
		   gemm_d);
}

sub EBUG () { 'Should not happen' }
sub EINVAL () { 'Invalid argument' }

# Machine parameters.
my $SMALL = 1 / DBL_MAX < DBL_MIN ? DBL_MIN : (1 + DBL_EPSILON) / DBL_MAX;
my $LARGE = 1 / $SMALL;

## Reduction operations.

# Dot product.
sub dot_d ($$$$$$$$$$;$)
{
  # Arguments.
  my ($n, $alpha, $x, $x_ind, $x_incr, $y, $y_ind, $y_incr, $beta, $r, $r_ind) = @_;

  # Return quickly.
  return undef if $n < 0;

  # Code.
  my $dot = 0;

  if ($alpha != 0)
    {
      foreach (1 .. $n)
	{
	  $dot += $$x[$x_ind] * $$y[$y_ind];

	  $x_ind += $x_incr;
	  $y_ind += $y_incr;
	}

      $dot *= $alpha
	if $alpha != 1;
    }

  if ($beta != 0)
    {
      my $r_val = ref ($r) ? $$r[$r_ind] : $r;

      $r_val *= $beta
	if $beta != 1;

      $dot += $r_val;
    }

  # Update scalar.
  $$r[$r_ind] = $dot
    if ref ($r);

  # Return value.
  $dot;
}

# Vector norms.
sub norm_d ($$$$$)
{
  # Arguments.
  my ($norm, $n, $x, $x_ind, $x_incr) = @_;

  # Return quickly.
  return 0 if $n <= 0;

  # Code.
  if ($norm == BLAS_ONE_NORM)
    {
      $norm = 0;

      foreach (1 .. $n)
	{
	  $norm += abs ($$x[$x_ind]);

	  $x_ind += $x_incr;
	}
    }
  elsif ($norm == BLAS_TWO_NORM || $norm == BLAS_FROBENIUS_NORM)
    {
      my ($sumsq, $scale) = sumsq_d ($n, $x, $x_ind, $x_incr);

      $norm = $scale * sqrt ($sumsq);
    }
  elsif ($norm == BLAS_INF_NORM)
    {
      (undef, $norm) = amax_val_d ($n, $x, $x_ind, $x_incr);
    }
  else
    {
      croak (EINVAL);
    }

  # Return value.
  $norm;
}

# Sum.
sub sum_d ($$$$)
{
  # Arguments.
  my ($n, $x, $x_ind, $x_incr) = @_;

  # Return quickly.
  return 0 if $n <= 0;

  # Code.
  my $sum = 0;

  foreach (1 .. $n)
    {
      $sum += $$x[$x_ind];

      $x_ind += $x_incr;
    }

  # Return value.
  $sum;
}

# Minimum value.
sub min_val_d ($$$$)
{
  # Arguments.
  my ($n, $x, $x_ind, $x_incr) = @_;

  # Return quickly.
  return (undef, 0) if $n <= 0;

  # Code.
  my $offs = 0;
  my $val = $$x[$x_ind];
  my $tem;

  foreach (1 .. $n - 1)
    {
      $x_ind += $x_incr;

      $tem = $$x[$x_ind];
      next unless $tem < $val;

      $offs = $_;
      $val = $tem;
    }

  # Return values.
  ($offs, $val);
}

# Minimum absolute value.
sub amin_val_d ($$$$)
{
  # Arguments.
  my ($n, $x, $x_ind, $x_incr) = @_;

  # Return quickly.
  return (undef, 0) if $n <= 0;

  # Code.
  my $offs = 0;
  my $val = abs ($$x[$x_ind]);
  my $tem;

  foreach (1 .. $n - 1)
    {
      $x_ind += $x_incr;

      $tem = abs ($$x[$x_ind]);
      next unless $tem < $val;

      $offs = $_;
      $val = $tem;
    }

  # Return values.
  ($offs, $val);
}

# Maximum value.
sub max_val_d ($$$$)
{
  # Arguments.
  my ($n, $x, $x_ind, $x_incr) = @_;

  # Return quickly.
  return (undef, 0) if $n <= 0;

  # Code.
  my $offs = 0;
  my $val = $$x[$x_ind];
  my $tem;

  foreach (1 .. $n - 1)
    {
      $x_ind += $x_incr;

      $tem = $$x[$x_ind];
      next unless $tem > $val;

      $offs = $_;
      $val = $tem;
    }

  # Return values.
  ($offs, $val);
}

# Maximum absolute value.
sub amax_val_d ($$$$)
{
  # Arguments.
  my ($n, $x, $x_ind, $x_incr) = @_;

  # Return quickly.
  return (undef, 0) if $n <= 0;

  # Code.
  my $offs = 0;
  my $val = abs ($$x[$x_ind]);
  my $tem;

  foreach (1 .. $n - 1)
    {
      $x_ind += $x_incr;

      $tem = abs ($$x[$x_ind]);
      next unless $tem > $val;

      $offs = $_;
      $val = $tem;
    }

  # Return values.
  ($offs, $val);
}

# Sum of squares.
sub sumsq_d ($$$$;$$)
{
  # Arguments.
  my ($n, $x, $x_ind, $x_incr, $sumsq, $scale) = @_;

  # Code.
  if ($n > 0)
    {
      my $tem;

      $sumsq //= 0;
      $scale //= 1;

      foreach (1 .. $n)
	{
	  if ($$x[$x_ind] != 0)
	    {
	      $tem = abs ($$x[$x_ind]);
	      if ($scale < $tem)
		{
		  $sumsq *= ($scale / $tem) ** 2;
		  $sumsq += 1;

		  $scale = $tem;
		}
	      else
		{
		  $sumsq += ($tem / $scale) ** 2;
		}
	    }

	  $x_ind += $x_incr;
	}
    }

  # Return values.
  ($sumsq, $scale);
}

## Vector operations.

# Scale.
sub scale_d ($$$$$)
{
  # Arguments.
  my ($n, $alpha, $x, $x_ind, $x_incr) = @_;

  # Return quickly.
  return if $alpha == 1;

  # Code.
  foreach (1 .. $n)
    {
      $$x[$x_ind] *= $alpha;

      $x_ind += $x_incr;
    }
}

# Reciprocal scale.
sub rscale_d ($$$$$)
{
  # Arguments.
  my ($n, $alpha, $x, $x_ind, $x_incr) = @_;

  # Return quickly.
  return if $n <= 0;

  # Code.
  my $mul;
  my $num = 1;
  my $den = $alpha;

  my $done = 0;
  until ($done)
    {
      my $num1 = $num / $LARGE;
      my $den1 = $den * $SMALL;

      if (abs ($den1) > abs ($num) && $num != 0)
	{
	  # Pre-multiply by $SMALL.
	  $mul = $SMALL;
	  $den = $den1;
	}
      elsif (abs ($num1) > abs ($den))
	{
	  # Pre-multiply by $LARGE.
	  $mul = $LARGE;
	  $num = $num1;
	}
      else
	{
	  $mul = $num / $den;
	  $done = 1;
	}

      scale_d ($n, $mul, $x, $x_ind, $x_incr);
    }
}

# Scaled vector accumulation.
sub axpby_d ($$$$$$$$$)
{
  # Arguments.
  my ($n, $alpha, $x, $x_ind, $x_incr, $beta, $y, $y_ind, $y_incr) = @_;

  # Return quickly.
  return if $n <= 0;

  # Code.
  if ($alpha == 0)
    {
      if ($beta == 0)
	{
	  foreach (1 .. $n)
	    {
	      $$y[$y_ind] = 0;

	      $y_ind += $y_incr;
	    }
	}
      elsif ($beta != 1)
	{
	  foreach (1 .. $n)
	    {
	      $$y[$y_ind] *= $beta;

	      $y_ind += $y_incr;
	    }
	}
    }
  elsif ($alpha == 1)
    {
      if ($beta == 0)
	{
	  foreach (1 .. $n)
	    {
	      $$y[$y_ind] = $$x[$x_ind];

	      $x_ind += $x_incr;
	      $y_ind += $y_incr;
	    }
	}
      elsif ($beta == 1)
	{
	  foreach (1 .. $n)
	    {
	      $$y[$y_ind] += $$x[$x_ind];

	      $x_ind += $x_incr;
	      $y_ind += $y_incr;
	    }
	}
      else
	{
	  foreach (1 .. $n)
	    {
	      $$y[$y_ind] *= $beta;
	      $$y[$y_ind] += $$x[$x_ind];

	      $x_ind += $x_incr;
	      $y_ind += $y_incr;
	    }
	}
    }
  else
    {
      if ($beta == 0)
	{
	  foreach (1 .. $n)
	    {
	      $$y[$y_ind] = $alpha * $$x[$x_ind];

	      $x_ind += $x_incr;
	      $y_ind += $y_incr;
	    }
	}
      elsif ($beta == 1)
	{
	  foreach (1 .. $n)
	    {
	      $$y[$y_ind] += $alpha * $$x[$x_ind];

	      $x_ind += $x_incr;
	      $y_ind += $y_incr;
	    }
	}
      else
	{
	  foreach (1 .. $n)
	    {
	      $$y[$y_ind] *= $beta;
	      $$y[$y_ind] += $alpha * $$x[$x_ind];

	      $x_ind += $x_incr;
	      $y_ind += $y_incr;
	    }
	}
    }
}

# Scaled vector addition.
sub waxpby_d ($$$$$$$$$$$$)
{
  # Arguments.
  my ($n, $alpha, $x, $x_ind, $x_incr, $beta, $y, $y_ind, $y_incr, $w, $w_ind, $w_incr) = @_;

  # Return quickly.
  return if $n <= 0;

  # Code.
  if ($alpha == 0)
    {
      if ($beta == 0)
	{
	  foreach (1 .. $n)
	    {
	      $$w[$w_ind] = 0;

	      $w_ind += $w_incr;
	    }
	}
      elsif ($beta == 1)
	{
	  foreach (1 .. $n)
	    {
	      $$w[$w_ind] = $$y[$y_ind];

	      $w_ind += $w_incr;
	      $y_ind += $y_incr;
	    }
	}
      else
	{
	  foreach (1 .. $n)
	    {
	      $$w[$w_ind] = $beta * $$y[$y_ind];

	      $w_ind += $w_incr;
	      $y_ind += $y_incr;
	    }
	}
    }
  elsif ($alpha == 1)
    {
      if ($beta == 0)
	{
	  foreach (1 .. $n)
	    {
	      $$w[$w_ind] = $$x[$x_ind];

	      $w_ind += $w_incr;
	      $x_ind += $x_incr;
	    }
	}
      elsif ($beta == 1)
	{
	  foreach (1 .. $n)
	    {
	      $$w[$w_ind] = $$x[$x_ind] + $$y[$y_ind];

	      $w_ind += $w_incr;
	      $x_ind += $x_incr;
	      $y_ind += $y_incr;
	    }
	}
      else
	{
	  foreach (1 .. $n)
	    {
	      $$w[$w_ind] = $$x[$x_ind] + $beta * $$y[$y_ind];

	      $w_ind += $w_incr;
	      $x_ind += $x_incr;
	      $y_ind += $y_incr;
	    }
	}
    }
  else
    {
      if ($beta == 0)
	{
	  foreach (1 .. $n)
	    {
	      $$w[$w_ind] = $alpha * $$x[$x_ind];

	      $w_ind += $w_incr;
	      $x_ind += $x_incr;
	    }
	}
      elsif ($beta == 1)
	{
	  foreach (1 .. $n)
	    {
	      $$w[$w_ind] = $alpha * $$x[$x_ind] + $$y[$y_ind];

	      $w_ind += $w_incr;
	      $x_ind += $x_incr;
	      $y_ind += $y_incr;
	    }
	}
      else
	{
	  foreach (1 .. $n)
	    {
	      $$w[$w_ind] = $alpha * $$x[$x_ind] + $beta * $$y[$y_ind];

	      $w_ind += $w_incr;
	      $x_ind += $x_incr;
	      $y_ind += $y_incr;
	    }
	}
    }
}

## Data movement with vectors.

# Copy vector.
sub copy_d ($$$$$$$)
{
  # Arguments.
  my ($n, $x, $x_ind, $x_incr, $y, $y_ind, $y_incr) = @_;

  # Return quickly.
  return if $n <= 0;

  # Code.
  foreach (1 .. $n)
    {
      $$y[$y_ind] = $$x[$x_ind];

      $x_ind += $x_incr;
      $y_ind += $y_incr;
    }
}

# Swap vectors.
sub swap_d ($$$$$$$)
{
  # Arguments.
  my ($n, $x, $x_ind, $x_incr, $y, $y_ind, $y_incr) = @_;

  # Return quickly.
  return if $n <= 0;

  # Code.
  my $tem;

  foreach (1 .. $n)
    {
      $tem = $$x[$x_ind];
      $$x[$x_ind] = $$y[$y_ind];
      $$y[$y_ind] = $tem;

      $x_ind += $x_incr;
      $y_ind += $y_incr;
    }
}

## Matrix/vector operations.

# General matrix/vector multiplication.
sub gemv_d ($$$$$$$$$$$$$$)
{
  # Arguments.
  my ($a_op, $m, $n, $alpha, $a, $a_ind, $a_incr, $x, $x_ind, $x_incr, $beta, $y, $y_ind, $y_incr) = @_;

  my $form = ($a_op == BLAS_NO_TRANS ? 1 :
	      ($a_op == BLAS_TRANS || $a_op == BLAS_CONJ_TRANS ? 2 :
	       0));

  croak (EINVAL)
    if $form == 0;

  # Return quickly.
  return if $m <= 0 || $n <= 0;

  # Code.
  if ($form == 1)
    {
      # y <- alpha * A * x + beta * y
      foreach (1 .. $m)
	{
	  dot_d ($n, $alpha, $a, $a_ind, 1, $x, $x_ind, $x_incr, $beta, $y, $y_ind);

	  $a_ind += $a_incr;
	  $y_ind += $y_incr;
	}

      return;
    }

  if ($form == 2)
    {
      # y <- alpha * A' * x + beta * y
      foreach (1 .. $n)
	{
	  dot_d ($m, $alpha, $a, $a_ind, $a_incr, $x, $x_ind, $x_incr, $beta, $y, $y_ind);

	  $a_ind += 1;
	  $y_ind += $y_incr;
	}

      return;
    }

  croak (EBUG);
}

## Matrix operations.

## Matrix/matrix operations.

# General matrix/matrix multiplication.
sub gemm_d ($$$$$$$$$$$$$$$$)
{
  # Arguments.
  my ($a_op, $b_op, $m, $n, $k, $alpha, $a, $a_ind, $a_incr, $b, $b_ind, $b_incr, $beta, $c, $c_ind, $c_incr) = @_;

  my $form = ($a_op == BLAS_NO_TRANS ?
	      ($b_op == BLAS_NO_TRANS ? 1 :
	       ($b_op == BLAS_TRANS || $b_op == BLAS_CONJ_TRANS ? 3 : 0)) :
	      ($a_op == BLAS_TRANS || $a_op == BLAS_CONJ_TRANS ?
	       ($b_op == BLAS_NO_TRANS ? 2 :
		($b_op == BLAS_TRANS || $b_op == BLAS_CONJ_TRANS ? 4 : 0)) :
	       0));

  croak (EINVAL)
    if $form == 0;

  # Return quickly.
  return if $m <= 0 || $n <= 0;

  # Code.
  $c_incr -= $n;

  if ($form == 1)
    {
      # C <- alpha * A * B + beta * C
      my $b_start = $b_ind;

      foreach (1 .. $m)
	{
	  foreach (1 .. $n)
	    {
	      dot_d ($k, $alpha, $a, $a_ind, 1, $b, $b_ind, $b_incr, $beta, $c, $c_ind);

	      ++$b_ind;
	      ++$c_ind;
	    }

	  $a_ind += $a_incr;
	  $b_ind = $b_start;
	  $c_ind += $c_incr;
	}

      return;
    }

  if ($form == 2)
    {
      # C <- alpha * A' * B + beta * C
      my $b_start = $b_ind;

      foreach (1 .. $m)
	{
	  foreach (1 .. $n)
	    {
	      dot_d ($k, $alpha, $a, $a_ind, $a_incr, $b, $b_ind, $b_incr, $beta, $c, $c_ind);

	      ++$b_ind;
	      ++$c_ind;
	    }

	  $a_ind += 1;
	  $b_ind = $b_start;
	  $c_ind += $c_incr;
	}

      return;
    }

  if ($form == 3)
    {
      # C <- alpha * A * B' + beta * C
      my $b_start = $b_ind;

      foreach (1 .. $m)
	{
	  foreach (1 .. $n)
	    {
	      dot_d ($k, $alpha, $a, $a_ind, 1, $b, $b_ind, 1, $beta, $c, $c_ind);

	      $b_ind += $b_incr;
	      $c_ind += 1;
	    }

	  $a_ind += $a_incr;
	  $b_ind = $b_start;
	  $c_ind += $c_incr;
	}

      return;
    }

  if ($form == 4)
    {
      # C <- alpha * A' * B' + beta * C
      my $b_start = $b_ind;

      foreach (1 .. $m)
	{
	  foreach (1 .. $n)
	    {
	      dot_d ($k, $alpha, $a, $a_ind, $a_incr, $b, $b_ind, 1, $beta, $c, $c_ind);

	      $b_ind += $b_incr;
	      $c_ind += 1;
	    }

	  $a_ind += 1;
	  $b_ind = $b_start;
	  $c_ind += $c_incr;
	}

      return;
    }

  croak (EBUG);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Math::BLAS::PP - pure Perl BLAS


=head1 SYNOPSIS

    use Math::BLAS::PP;


=head1 DESCRIPTION

Don't use this yourself.


=head2 Reduction Operations

=over

=item C<dot_d> (I<n>, I<alpha>, I<x>, I<x_ind>, I<x_incr>, I<y>, I<y_ind>, I<y_incr>, I<beta>, I<r>, I<r_ind>)

Dot product.


=item C<norm_d> (I<norm>, I<n>, I<x>, I<x_ind>, I<x_incr>)

Vector norms.


=item C<sum_d> (I<n>, I<x>, I<x_ind>, I<x_incr>)

Sum of vector elements.


=item C<min_val_d> (I<n>, I<x>, I<x_ind>, I<x_incr>)

Minimum value and location.


=item C<amin_val_d> (I<n>, I<x>, I<x_ind>, I<x_incr>)

Minimum absolute value and location.


=item C<max_val_d> (I<n>, I<x>, I<x_ind>, I<x_incr>)

Maximum value and location.


=item C<amax_val_d> (I<n>, I<x>, I<x_ind>, I<x_incr>)

Maximum absolute value and location.


=item C<sumsq_d> (I<n>, I<x>, I<x_ind>, I<x_incr>, I<sumsq>, I<scale>)

Sum of squares.

=back


=head2 Vector Operations

=over

=item C<scale_d> (I<n>, I<alpha>, I<x>, I<x_ind>, I<x_incr>)

Scale.


=item C<rscale_d> (I<n>, I<alpha>, I<x>, I<x_ind>, I<x_incr>)

Reciprocal scale.


=item C<axpby_d> (I<n>, I<alpha>, I<x>, I<x_ind>, I<x_incr>, I<beta>, I<y>, I<y_ind>, I<y_incr>)

Scaled vector accumulation.


=item C<waxpby_d> (I<n>, I<alpha>, I<x>, I<x_ind>, I<x_incr>, I<beta>, I<y>, I<y_ind>, I<y_incr>, I<w>, I<w_ind>, I<w_incr>)

Scaled vector addition.

=back


=head2 Data Movement with Vectors

=over

=item C<copy_d> (I<n>, I<x>, I<x_ind>, I<x_incr>, I<y>, I<y_ind>, I<y_incr>)

Copy vector elements.


=item C<swap_d> (I<n>, I<x>, I<x_ind>, I<x_incr>, I<y>, I<y_ind>, I<y_incr>)

Interchange vector elements.

=back


=head2 Matrix/Vector Operations

=over

=item C<gemv_d> (I<a_op>, I<m>, I<n>, I<alpha>, I<a>, I<a_ind>, I<a_incr>, I<x>, I<x_ind>, I<x_incr>, I<beta>, I<y>, I<y_ind>, I<y_incr>)

General matrix/vector multiplication.

=back


=head2 Matrix/Matrix Operations

=over

=item C<gemm_d> (I<a_op>, I<b_op>, I<m>, I<n>, I<k>, I<alpha>, I<a>, I<a_ind>, I<a_incr>, I<b>, I<b_ind>, I<b_incr>, I<beta>, I<c>, I<c_ind>, I<c_incr>)

General matrix/matrix multiplication.

=back


=head1 SEE ALSO

Math::L<BLAS|Math::BLAS>


=head1 AUTHOR

Ralph Schleicher <rs@ralph-schleicher.de>

=cut

## Math/BLAS/PP.pm ends here
