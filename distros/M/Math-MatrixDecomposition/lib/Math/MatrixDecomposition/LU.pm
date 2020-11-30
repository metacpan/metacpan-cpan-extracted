## Math/MatrixDecomposition/LU.pm --- LU decomposition.

# Copyright (C) 2010 Ralph Schleicher.  All rights reserved.

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

## Code:

package Math::MatrixDecomposition::LU;

use strict;
use warnings;
use Carp;
use Exporter qw(import);
use Scalar::Util qw(looks_like_number);

use Math::BLAS;
use Math::MatrixDecomposition::Util qw(mod min);

BEGIN
{
  our $VERSION = '1.04';
  our @EXPORT_OK = qw(lu);
}

# Create a LU decomposition (convenience function).
sub lu
{
  __PACKAGE__->new (@_);
}

# Standard constructor.
sub new
{
  my $class = shift;
  my $self =
    {
     # LU matrix in row major layout.
     LU => [],

     # Number of matrix rows and columns.
     rows => 0,
     columns => 0,

     # Pivot row indices (row permutations).
     pivot => [],

     # Sign of determinant.  A value of zero means that
     # the matrix is singular.
     sign => 0,
    };

  bless ($self, ref ($class) || $class);

  # Process arguments.
  $self->decompose (@_)
    if @_ > 0;

  # Return object.
  $self;
}

# LU decomposition.
sub decompose
{
  my $self = shift;

  # Check arguments.
  my $a = shift;

  my $m = @_ > 0 && looks_like_number ($_[0]) ? shift : sqrt (@$a);
  my $n = @_ > 0 && looks_like_number ($_[0]) ? shift : $m ? @$a / $m : 0;

  croak ('Invalid argument')
    if (@$a != ($m * $n)
	|| mod ($m, 1) != 0 || $m < 1
	|| mod ($n, 1) != 0 || $n < 1);

  # Get properties.
  my %prop = @_;

  $prop{capture} //= 0;

  # Index of last row/column.
  my $last_row = $m - 1;
  my $last_col = $n - 1;

  # Matrix elements.
  if ($prop{capture})
    {
      # Work in-place.
      $$self{LU} = $a;
    }
  else
    {
      # Copy matrix elements.
      $$self{LU} //= [];
      @{$$self{LU}} = @$a;
      $a = $$self{LU};
    }

  # Matrix size.
  $$self{rows} = $m;
  $$self{columns} = $n;

  # Pivot row indices (row permutations).
  my $pivot = $$self{pivot};

  @$pivot = ();

  # Sign of determinant.
  my $sign = 1;

  # Work variables.
  my ($i, $j, $k, $p, $row, $tem);

  for $k (0 .. min ($last_row, $last_col))
    {
      # Search pivot element.
      $p = $k + (blas_amax_val ($m - $k, $a,
				x_ind => $k * $n + $k,
				x_incr => $n))[0];

      push (@$pivot, $p);

      # Swap rows.
      if ($p != $k)
	{
	  blas_swap ($n, $a, $a,
		     x_ind => $k * $n,
		     y_ind => $p * $n);

	  $sign = - $sign;
	}

      # Divide by the pivot element.
      if ($$a[$k * $n + $k] == 0)
	{
	  $sign = 0;
	  next;
	}

      for $i ($k + 1 .. $last_row)
	{
	  $$a[$i * $n + $k] /= $$a[$k * $n + $k];

	  blas_axpby ($last_col - $k, $a, $a,
		      alpha => - $$a[$i * $n + $k],
		      x_ind => $k * $n + $k + 1,
		      y_ind => $i * $n + $k + 1);
	}
    }

  # Save sign of determinant.
  $$self{sign} = $sign;

  # Return object.
  $self;
}

# Solve a system of linear equations.
sub solve
{
  my $self = shift;

  my $b = shift;
  my $x = shift;

  # LU matrix elements.
  my $a = $$self{LU};

  # Number of matrix rows and columns.
  my $m = $$self{rows};
  my $n = $$self{columns};

  croak ('Invalid argument')
    if @$b == 0 || @$b % $m != 0;

  my $l = @$b / $m;

  # Copy right-hand side.
  if (defined ($x))
    {
      @$x = @$b;
    }
  else
    {
      # Work in-place.
      $x = $b;
    }

  # Index of last row/column.
  my $last_row = $m - 1;
  my $last_col = $n - 1;
  my $last_vec = $l - 1;

  # Pivot row indices.
  my $pivot = $$self{pivot};

  # Work variables.
  my ($i, $j, $k, $p, $row, $tem);

  if ($l == 1)
    {
      # Apply row permutations.
      for $i (0 .. $#$pivot)
	{
	  $p = $$pivot[$i];
	  next if $p == $i;

	  @$x[$i, $p] = @$x[$p, $i];
	}

      # Forward substitution, that is solve 'Ly = b' for 'y'.
      # Elements of 'y' are saved in 'x'.
      for $i (1 .. $last_row)
	{
	  $row = $i * $n;

	  for $j (0 .. $i - 1)
	    {
	      $$x[$i] -= $$x[$j] * $$a[$row + $j];
	    }
	}

      # Backward substitution, that is solve 'Ux = y' for 'x'.
      for $i (reverse (0 .. $last_row))
	{
	  $row = $i * $n;

	  if ($$a[$row + $i] == 0)
	    {
	      # Matrix A is singular.
	      return unless $$x[$i] == 0;
	    }
	  else
	    {
	      for $j ($i + 1 .. $last_col)
		{
		  $$x[$i] -= $$x[$j] * $$a[$row + $j];
		}

	      $$x[$i] /= $$a[$row + $i];
	    }
	}
    }
  else
    {
      # Matrix A is singular.
      return if $$self{sign} == 0;

      # Apply row permutations.
      for $i (0 .. $#$pivot)
	{
	  $p = $$pivot[$i];
	  next if $p == $i;

	  blas_swap ($l, $x, $x,
		     x_ind => $i * $l,
		     y_ind => $p * $l);
	}

      # Forward substitution.
      for $k (0 .. $last_col)
	{
	  for $i ($k + 1 .. $last_col)
	    {
	      blas_axpby ($l, $x, $x,
			  alpha => - $$a[$i * $n + $k],
			  x_ind => $k * $l,
			  y_ind => $i * $l);
	    }
	}

      # Backward substitution.
      for $k (reverse (0 .. $last_col))
	{
	  blas_rscale ($l, $x,
		       alpha => $$a[$k * $n + $k],
		       x_ind => $k * $l);

	  for $i (0 .. $k - 1)
	    {
	      blas_axpby ($l, $x, $x,
			  alpha => - $$a[$i * $n + $k],
			  x_ind => $k * $l,
			  y_ind => $i * $l);
	    }
	}
    }

  # Resize result.
  splice (@$x, $n * $l)
    if $m > $n;

  # Fix rounding errors.
  for (@$x)
    {
      $_ = 0 + "$_";
    }

  # Return value.
  $x;
}

# Determinant.
sub det
{
  my $self = shift;

  my $m = $$self{rows};
  my $n = $$self{columns};

  croak ('Matrix has to be square')
    if $m != $n;

  # Calculate determinant.
  my $det = $$self{sign};

  if ($det)
    {
      my $u = $$self{LU};

      my $ind = 0;
      my $incr = $n + 1;

      for (1 .. $n)
	{
	  $det *= $$u[$ind];
	  $ind += $incr;
	}
    }

  $det;
}

1;

__END__

=pod

=head1 NAME

Math::MatrixDecomposition::LU - LU decomposition


=head1 SYNOPSIS

Object-oriented interface.

    use Math::MatrixDecomposition::LU;

    $LU = Math::MatrixDecomposition::LU->new;
    $LU->decompose ($A = [...]);
    $LU->solve ($b = [...]);

    # Decomposition is the default action for 'new'.
    # This one-liner is equivalent to the command sequence above.
    Math::MatrixDecomposition::LU->new ($A = [...])->solve ($b = [...]);

The procedural form is even shorter.

    use Math::MatrixDecomposition qw(lu);

    lu ($A = [...])->solve ($b = [...]);


=head1 DESCRIPTION


=head2 Object Instantiation

=over

=item C<lu> (...)

The C<lu> function is the short form of
C<< Math::MatrixDecomposition::LU->new >> (which see).
The C<lu> function has to be used as a subroutine.
It is not exported by default.

=item C<new> (...)

Create a new object.  Any arguments are forwarded to the C<decompose>
method (which see).  The C<new> constructor can be used as a class or
instance method.

=back


=head2 Instance Methods

=over

=item C<decompose> (I<a>, I<m>, I<n>, ...)

Perform a LU decomposition with partial pivoting of a real matrix.

=over

=item *

First argument I<a> is an array reference to the matrix elements.
Matrix elements are interpreted in row-major layout.

=item *

Optional second argument I<m> is the number of matrix rows.
If omitted, it is assumed that the matrix is square.

=item *

Optional third argument I<n> is the number of matrix columns.  If
omitted, the number of matrix columns is calculated automatically.

=item *

Remaining arguments are property/value pairs with the following meaning.

=over

=item C<capture> I<flag>

Whether or not to decompose the matrix I<a> in-place.  Default is false.

=back

=back

Return value is the LU object.


=item C<solve> (I<b>, I<x>)

Solve a system of linear equations 'A X = B'.

The LU object represents the coefficients of the left-hand side of the
system, that is the matrix 'A'.

=over

=item *

First argument I<b> is an array reference.  Array elements are the
right-hand side of the system.  Argument I<b> may have more than one
column (matrix elements of I<b> are interpreted in row-major layout).

=item *

Optional second argument I<x> is an array reference.  The solution of
the system is saved in I<x>.  Default is to save the solution in place
of I<b>.

=back

Return value is the solution I<x>.


=item C<det>

Return the value of the determinant.

=back


=head1 SEE ALSO

Math::L<MatrixDecomposition|Math::MatrixDecomposition>


=head2 External Links

=over

=item *

Wikipedia, L<http://en.wikipedia.org/wiki/LU_decomposition>

=item *

MathWorld, L<http://mathworld.wolfram.com/LUDecomposition.html>

=back


=head1 AUTHOR

Ralph Schleicher <ralph@cpan.org>

=cut

## Math/MatrixDecomposition/LU.pm ends here
