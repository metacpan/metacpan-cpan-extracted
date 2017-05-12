## Math/BLAS/Legacy.pm --- original Level 1, 2, and 3 BLAS.

# Copyright (C) 2010 Ralph Schleicher.  All rights reserved.

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

## Code:

package Math::BLAS::Legacy;

use strict;
use warnings;
use Exporter qw(import);

use Math::BLAS::Enum;
use Math::BLAS::PP;

BEGIN
{
  our $VERSION = '1.01';
  our @EXPORT = ();
  our @EXPORT_OK = ();
  our %EXPORT_TAGS = ();

  # Named constants.
  $EXPORT_TAGS{enum}
    = [ @Math::BLAS::Enum::EXPORT ];
  push (@EXPORT_OK, @{ $EXPORT_TAGS{enum} });
  push (@EXPORT, @{ $EXPORT_TAGS{enum} });

  # Subroutines.
  $EXPORT_TAGS{sub}
    = [qw(blas_dcopy
	  blas_dswap
	  blas_dset
	  blas_dscal
	  blas_daxpy
	  blas_ddot
	  blas_dasum
	  blas_dnrm2
	  blas_idamax
	  blas_dgemv
	  blas_dgemm)];
  push (@EXPORT_OK, @{ $EXPORT_TAGS{sub} });
  push (@EXPORT, @{ $EXPORT_TAGS{sub} });

  # Define aliases.
  if (1)
    {
      no strict 'refs';
      my ($s, @bare) = ();

      foreach (@{ $EXPORT_TAGS{sub} })
	{
	  ($s = $_) =~ s/\Ablas_//;

	  *{$s} = \&{$_};
	  push (@bare, $s);
	}

      $EXPORT_TAGS{bare} = [@bare];
      push (@EXPORT_OK, @bare);
    }

  $EXPORT_TAGS{all} = [ @EXPORT_OK ];
}

## Level 1.

# Copy vector elements.
sub blas_dcopy ($$$$$$$)
{
  my ($n, $x, $x_ind, $x_incr, $y, $y_ind, $y_incr) = @_;

  copy_d (int ($n),
	  $x,
	  int ($x_ind),
	  int ($x_incr),
	  $y,
	  int ($y_ind),
	  int ($y_incr));
}

# Interchange vector elements.
sub blas_dswap ($$$$$$$)
{
  my ($n, $x, $x_ind, $x_incr, $y, $y_ind, $y_incr) = @_;

  swap_d (int ($n),
	  $x,
	  int ($x_ind),
	  int ($x_incr),
	  $y,
	  int ($y_ind),
	  int ($y_incr));
}

# Set vector elements to a constant.
sub blas_dset ($$$$$)
{
  my ($n, $alpha, $x, $x_ind, $x_incr) = @_;

  $x_ind = int ($x_ind);
  $x_incr = int ($x_incr);

  foreach (1 .. $n)
    {
      $$x[$x_ind] = $alpha;

      $x_ind += $x_incr;
    }
}

# Multiply vector elements by a constant.
sub blas_dscal ($$$$$)
{
  my ($n, $alpha, $x, $x_ind, $x_incr) = @_;

  axpby_d (int ($n),
	   0,
	   undef,
	   0,
	   1,
	   $alpha,
	   $x,
	   int ($x_ind),
	   int ($x_incr));
}

# Accumulate multiples of vector elements.
sub blas_daxpy ($$$$$$$$)
{
  my ($n, $alpha, $x, $x_ind, $x_incr, $y, $y_ind, $y_incr) = @_;

  axpby_d (int ($n),
	   $alpha,
	   $x,
	   int ($x_ind),
	   int ($x_incr),
	   1,
	   $y,
	   int ($y_ind),
	   int ($y_incr));
}

# Inner product.
sub blas_ddot ($$$$$$$)
{
  my ($n, $x, $x_ind, $x_incr, $y, $y_ind, $y_incr) = @_;

  dot_d (int ($n),
	 1,
	 $x,
	 int ($x_ind),
	 int ($x_incr),
	 $y,
	 int ($y_ind),
	 int ($y_incr),
	 0,
	 0,
	 0);
}

# Return sum of absolute values.
sub blas_dasum ($$$$)
{
  my ($n, $x, $x_ind, $x_incr) = @_;

  norm_d (BLAS_ONE_NORM,
	  int ($n),
	  $x,
	  int ($x_ind),
	  int ($x_incr));
}

# Return vector norm.
sub blas_dnrm2 ($$$$)
{
  my ($n, $x, $x_ind, $x_incr) = @_;

  norm_d (BLAS_TWO_NORM,
	  int ($n),
	  $x,
	  int ($x_ind),
	  int ($x_incr));
}

# Return index offset of first element having maximum absolute value.
sub blas_idamax ($$$$)
{
  my ($n, $x, $x_ind, $x_incr) = @_;

  (amax_val_d (int ($n),
	       $x,
	       int ($x_ind),
	       int ($x_incr)))[0];
}

## Level 2.

# General matrix/vector multiplication.
sub blas_dgemv ($$$$$$$$$$$$$$)
{
  my ($a_op, $m, $n, $alpha, $a, $a_ind, $a_incr, $x, $x_ind, $x_incr, $beta, $y, $y_ind, $y_incr) = @_;

  gemv_d ($a_op,
	  int ($m),
	  int ($n),
	  $alpha,
	  $a,
	  int ($a_ind),
	  int ($a_incr),
	  $x,
	  int ($x_ind),
	  int ($x_incr),
	  $beta,
	  $y,
	  int ($y_ind),
	  int ($y_incr));
}

## Level 3.

# General matrix/matrix multiplication.
sub blas_dgemm ($$$$$$$$$$$$$$$$)
{
  my ($a_op, $b_op, $m, $n, $k, $alpha, $a, $a_ind, $a_incr, $b, $b_ind, $b_incr, $beta, $c, $c_ind, $c_incr) = @_;

  gemm_d ($a_op,
	  $b_op,
	  int ($m),
	  int ($n),
	  int ($k),
	  $alpha,
	  $a,
	  int ($a_ind),
	  int ($a_incr),
	  $b,
	  int ($b_ind),
	  int ($b_incr),
	  $beta,
	  $c,
	  int ($c_ind),
	  int ($c_incr));
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Math::BLAS::Legacy - original Level 1, 2, and 3 BLAS


=head1 SYNOPSIS

    use Math::BLAS::Legacy;


=head1 DESCRIPTION


=head2 Level 1 BLAS

=over

=item C<blas_dcopy> (I<n>, I<x>, I<x_ind>, I<x_incr>, I<y>, I<y_ind>, I<y_incr>)

Copy array elements.

=over

=item *

First argument I<n> is the number of array elements.

=item *

Second argument I<x> is the source array (an array reference).

=item *

Third argument I<x_ind> is the array index of the first array element
for the array I<x>.

=item *

Fourth argument I<x_incr> is the array index increment for the array
I<x>.

=item *

Fifth argument I<y> is the destination array (an array reference).

=item *

Sixth argument I<y_ind> is the array index of the first array element
for the array I<y>.

=item *

Seventh argument I<y_incr> is the array index increment for the array
I<y>.

=back

Arguments I<x> and I<y> may be the same array.


=item C<blas_dswap> (I<n>, I<x>, I<x_ind>, I<x_incr>, I<y>, I<y_ind>, I<y_incr>)

Interchange array elements.

=over

=item *

First argument I<n> is the number of array elements.

=item *

Second argument I<x> is the first array (an array reference).

=item *

Third argument I<x_ind> is the array index of the first array element
for the array I<x>.

=item *

Fourth argument I<x_incr> is the array index increment for the array
I<x>.

=item *

Fifth argument I<y> is the second array (an array reference).

=item *

Sixth argument I<y_ind> is the array index of the first array element
for the array I<y>.

=item *

Seventh argument I<y_incr> is the array index increment for the array
I<y>.

=back

Arguments I<x> and I<y> may be the same array.


=item C<blas_dset> (I<n>, I<alpha>, I<x>, I<x_ind>, I<x_incr>)

Set array elements to a constant.

=over

=item *

First argument I<n> is the number of array elements.

=item *

Second argument I<alpha> is the constant value.

=item *

Third argument I<x> is the array (an array reference).

=item *

Fourth argument I<x_ind> is the array index of the first array element.

=item *

Fifth argument I<x_incr> is the array index increment.

=back


=item C<blas_dscal> (I<n>, I<alpha>, I<x>, I<x_ind>, I<x_incr>)

Multiply array elements by a constant.

=over

=item *

First argument I<n> is the number of array elements.

=item *

Second argument I<alpha> is the constant value.

=item *

Third argument I<x> is the array (an array reference).

=item *

Fourth argument I<x_ind> is the array index of the first array element.

=item *

Fifth argument I<x_incr> is the array index increment.

=back


=item C<blas_daxpy> (I<n>, I<alpha>, I<x>, I<x_ind>, I<x_incr>, I<y>, I<y_ind>, I<y_incr>)

Accumulate multiples of array elements.

=over

=item *

First argument I<n> is the number of array elements.

=item *

Second argument I<alpha> is the multiplier.

=item *

Third argument I<x> is the multiplicand array (an array reference).

=item *

Fourth argument I<x_ind> is the array index of the first array element
for the array I<x>.

=item *

Fifth argument I<x_incr> is the array index increment for the array
I<x>.

=item *

Sixth argument I<y> is the accumulator array (an array reference).

=item *

Seventh argument I<y_ind> is the array index of the first array element
for the array I<y>.

=item *

Eighth argument I<y_incr> is the array index increment for the array
I<y>.

=back


=item C<blas_ddot> (I<n>, I<x>, I<x_ind>, I<x_incr>, I<y>, I<y_ind>, I<y_incr>)

Return the inner product of two vectors.

=over

=item *

First argument I<n> is the number of array elements.

=item *

Second argument I<x> is the left-hand side operand (an array reference).

=item *

Third argument I<x_ind> is the array index of the first array element
for the array I<x>.

=item *

Fourth argument I<x_incr> is the array index increment for the array
I<x>.

=item *

Fifth argument I<y> is the right-hand side operand (an array reference).

=item *

Sixth argument I<y_ind> is the array index of the first array element
for the array I<y>.

=item *

Seventh argument I<y_incr> is the array index increment for the array
I<y>.

=back


=item C<blas_dasum> (I<n>, I<x>, I<x_ind>, I<x_incr>)

Return the sum of the absolute values, that is the one-norm of a vector.

=over

=item *

First argument I<n> is the number of array elements.

=item *

Second argument I<x> is the array (an array reference).

=item *

Third argument I<x_ind> is the array index of the first array element
for the array I<x>.

=item *

Fourth argument I<x_incr> is the array index increment for the array
I<x>.

=back


=item C<blas_dnrm2> (I<n>, I<x>, I<x_ind>, I<x_incr>)

Return the two-norm (Euclidean norm) of a vector.

=over

=item *

First argument I<n> is the number of array elements.

=item *

Second argument I<x> is the array (an array reference).

=item *

Third argument I<x_ind> is the array index of the first array element
for the array I<x>.

=item *

Fourth argument I<x_incr> is the array index increment for the array
I<x>.

=back


=item C<blas_idamax> (I<n>, I<x>, I<x_ind>, I<x_incr>)

Return the index offset of the first array element having the maximum
absolute value.

=over

=item *

First argument I<n> is the number of array elements to search.

=item *

Second argument I<x> is the array (an array reference).

=item *

Third argument I<x_ind> is the array index of the first array element
for the array I<x>.

=item *

Fourth argument I<x_incr> is the array index increment for the array
I<x>.

=back

=back


=head2 Level 2 BLAS

The underlying mathematical formulation is

=over

S<I<y> ← α I<A>·I<x> + β I<y>>

=back

where I<A> is a S<(I<m>, I<n>) matrix>, I<x> and I<y> are vectors, and
α and β are scalars.

If β is zero, I<y> is set to the result of the matrix/vector
multiplication.  If β is one, the result of the matrix/vector
multiplication is added to I<y>.  Otherwise, I<y> is scaled by β
before adding the result of the matrix/vector multiplication.

=over

=item C<blas_dgemv> (I<a_op>, I<m>, I<n>, I<alpha>, I<a>, I<a_ind>, I<a_incr>, I<x>, I<x_ind>, I<x_incr>, I<beta>, I<y>, I<y_ind>, I<y_incr>)

General matrix/vector multiplication.

=over

=item *

First argument I<a_op> is the transpose operator for the matrix I<A>.
Value is either C<BLAS_NO_TRANS> or C<BLAS_TRANS>.

=item *

Second argument I<m> is the number of matrix rows.

=item *

Third argument I<n> is the number of matrix columns.

=item *

Fourth argument I<alpha> is the multiplier.

=item *

Fifth argument I<a> is the matrix operand (an array reference).

=item *

Sixth argument I<a_ind> is the array index of the first array element
for the array I<a>.

=item *

Seventh argument I<a_incr> is the array index increment for the array
I<a>.

=item *

Eighth argument I<x> is the vector operand (an array reference).

=item *

Ninth argument I<x_ind> is the array index of the first array element
for the array I<x>.

=item *

Tenth argument I<x_incr> is the array index increment for the array
I<x>.

=item *

Eleventh argument I<beta> is the scale factor for the result vector.

=item *

Twelfth argument I<y> is the result vector (an array reference).

=item *

Thirteenth argument I<y_ind> is the array index of the first array element
for the array I<y>.

=item *

Fourteenth argument I<y_incr> is the array index increment for the array
I<y>.

=back

=back


=head2 Level 3 BLAS

The underlying mathematical formulation is

=over

S<I<C> ← α I<A>·I<B> + β I<C>>

=back

where I<C> is a S<(I<m>, I<n>) matrix>, I<A> and I<B> are matrices, and
α and β are scalars.

If β is zero, I<C> is set to the result of the matrix/matrix
multiplication.  If β is one, the result of the matrix/matrix
multiplication is added to I<C>.  Otherwise, I<C> is scaled by β
before adding the result of the matrix/matrix multiplication.

=over

=item C<blas_dgemm> (I<a_op>, I<b_op>, I<m>, I<n>, I<k>, I<alpha>, I<a>, I<a_ind>, I<a_incr>, I<b>, I<b_ind>, I<b_incr>, I<beta>, I<c>, I<c_ind>, I<c_incr>)

General matrix/matrix multiplication.

=over

=item *

First argument I<a_op> is the transpose operator for the matrix I<A>.
Value is either C<BLAS_NO_TRANS> or C<BLAS_TRANS>.

=item *

Second argument I<b_op> is the transpose operator for the matrix I<B>.
Value is either C<BLAS_NO_TRANS> or C<BLAS_TRANS>.

=item *

Third argument I<m> is the number of matrix rows.

=item *

Fourth argument I<n> is the number of matrix columns.

=item *

Fifth argument I<k> is the number of matrix columns of the matrix I<A>
and the number of matrix rows of the matrix I<B>.

=item *

Sixth argument I<alpha> is the multiplier.

=item *

Seventh argument I<a> is the left-hand side matrix operand (an array
reference).

=item *

Eighth argument I<a_ind> is the array index of the first array element
for the array I<a>.

=item *

Ninth argument I<a_incr> is the array index increment for the array
I<a>.

=item *

Tenth argument I<b> is the right-hand side matrix operand (an array
reference).

=item *

Eleventh argument I<b_ind> is the array index of the first array element
for the array I<b>.

=item *

Twelfth argument I<b_incr> is the array index increment for the array
I<b>.

=item *

Thirteenth argument I<beta> is the scale factor for the result matrix.

=item *

Fourteenth argument I<c> is the result matrix (an array reference).

=item *

Fifteenth argument I<c_ind> is the array index of the first array element
for the array I<c>.

=item *

Sixteenth argument I<c_incr> is the array index increment for the array
I<c>.

=back

=back


=head1 SEE ALSO

Math::BLAS::L<Enum|Math::BLAS::Enum>


=head1 AUTHOR

Ralph Schleicher <rs@ralph-schleicher.de>

=cut

## Math/BLAS/Legacy.pm ends here
