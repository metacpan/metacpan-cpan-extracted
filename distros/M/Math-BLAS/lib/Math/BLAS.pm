## Math/BLAS.pm --- basic linear algebra subroutines.

# Copyright (C) 2010 Ralph Schleicher.  All rights reserved.

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

## Code:

package Math::BLAS;

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
    = [qw(blas_dot
	  blas_norm
	  blas_sum
	  blas_min_val
	  blas_amin_val
	  blas_max_val
	  blas_amax_val
	  blas_sumsq
	  blas_rscale
	  blas_axpby
	  blas_waxpby
	  blas_copy
	  blas_swap
	  blas_gemv
	  blas_gemm)];
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

# Dot product.
sub blas_dot ($$$%)
{
  my ($n, $x, $y, %opt) = @_;

  dot_d (int ($n),
	 $opt{alpha} // 1,
	 $x,
	 int ($opt{x_ind} // 0),
	 int ($opt{x_incr} // 1),
	 $y,
	 int ($opt{y_ind} // 0),
	 int ($opt{y_incr} // 1),
	 $opt{beta} // 0,
	 $opt{r} // 0,
	 int ($opt{r_ind} // 0));
}

# Vector norms.
sub blas_norm ($$%)
{
  my ($n, $x, %opt) = @_;

  norm_d ($opt{norm} // BLAS_ONE_NORM,
	  int ($n),
	  $x,
	  int ($opt{x_ind} // 0),
	  int ($opt{x_incr} // 1));
}

# Sum.
sub blas_sum ($$%)
{
  my ($n, $x, %opt) = @_;

  sum_d (int ($n),
	 $x,
	 int ($opt{x_ind} // 0),
	 int ($opt{x_incr} // 1));
}

# Minimum value.
sub blas_min_val ($$%)
{
  my ($n, $x, %opt) = @_;

  min_val_d (int ($n),
	     $x,
	     int ($opt{x_ind} // 0),
	     int ($opt{x_incr} // 1));
}

# Minimum absolute value.
sub blas_amin_val ($$%)
{
  my ($n, $x, %opt) = @_;

  amin_val_d (int ($n),
	      $x,
	      int ($opt{x_ind} // 0),
	      int ($opt{x_incr} // 1));
}

# Maximum value.
sub blas_max_val ($$%)
{
  my ($n, $x, %opt) = @_;

  max_val_d (int ($n),
	     $x,
	     int ($opt{x_ind} // 0),
	     int ($opt{x_incr} // 1));
}

# Maximum absolute value.
sub blas_amax_val ($$%)
{
  my ($n, $x, %opt) = @_;

  amax_val_d (int ($n),
	      $x,
	      int ($opt{x_ind} // 0),
	      int ($opt{x_incr} // 1));
}

# Sum of squares.
sub blas_sumsq ($$%)
{
  my ($n, $x, %opt) = @_;

  sumsq_d (int ($n),
	   $x,
	   int ($opt{x_ind} // 0),
	   int ($opt{x_incr} // 1),
	   $opt{sumsq},
	   $opt{scale});
}

# Reciprocal scale.
sub blas_rscale ($$%)
{
  my ($n, $x, %opt) = @_;

  rscale_d (int ($n),
	    $opt{alpha} // 1,
	    $x,
	    int ($opt{x_ind} // 0),
	    int ($opt{x_incr} // 1));
}

# Scaled vector accumulation.
sub blas_axpby ($$$%)
{
  my ($n, $x, $y, %opt) = @_;

  axpby_d (int ($n),
	   $opt{alpha} // 1,
	   $x,
	   int ($opt{x_ind} // 0),
	   int ($opt{x_incr} // 1),
	   $opt{beta} // 1,
	   $y,
	   int ($opt{y_ind} // 0),
	   int ($opt{y_incr} // 1));
}

# Scaled vector addition.
sub blas_waxpby ($$$$%)
{
  my ($n, $x, $y, $w, %opt) = @_;

  waxpby_d (int ($n),
	    $opt{alpha} // 1,
	    $x,
	    int ($opt{x_ind} // 0),
	    int ($opt{x_incr} // 1),
	    $opt{beta} // 1,
	    $y,
	    int ($opt{y_ind} // 0),
	    int ($opt{y_incr} // 1),
	    $w,
	    int ($opt{w_ind} // 0),
	    int ($opt{w_incr} // 1));
}

# Copy vector.
sub blas_copy ($$$%)
{
  my ($n, $x, $y, %opt) = @_;

  copy_d (int ($n),
	  $x,
	  int ($opt{x_ind} // 0),
	  int ($opt{x_incr} // 1),
	  $y,
	  int ($opt{y_ind} // 0),
	  int ($opt{y_incr} // 1));
}

# Swap vectors.
sub blas_swap ($$$%)
{
  my ($n, $x, $y, %opt) = @_;

  swap_d (int ($n),
	  $x,
	  int ($opt{x_ind} // 0),
	  int ($opt{x_incr} // 1),
	  $y,
	  int ($opt{y_ind} // 0),
	  int ($opt{y_incr} // 1));
}

# General matrix/vector multiplication.
sub blas_gemv ($$$$$%)
{
  my ($m, $n, $a, $x, $y, %opt) = @_;

  my $a_op = $opt{a_op} // BLAS_NO_TRANS;

  gemv_d ($a_op,
	  int ($m),
	  int ($n),
	  $opt{alpha} // 1,
	  $a,
	  int ($opt{a_ind} // 0),
	  int ($opt{a_incr} // ($a_op == BLAS_NO_TRANS ? $n : $m)),
	  $x,
	  int ($opt{x_ind} // 0),
	  int ($opt{x_incr} // 1),
	  $opt{beta} // 0,
	  $y,
	  int ($opt{y_ind} // 0),
	  int ($opt{y_incr} // 1));
}

# General matrix/matrix multiplication.
sub blas_gemm ($$$$$$%)
{
  my ($m, $n, $k, $a, $b, $c, %opt) = @_;

  my $a_op = $opt{a_op} // BLAS_NO_TRANS;
  my $b_op = $opt{b_op} // BLAS_NO_TRANS;

  gemm_d ($a_op,
	  $b_op,
	  int ($m),
	  int ($n),
	  int ($k),
	  $opt{alpha} // 1,
	  $a,
	  int ($opt{a_ind} // 0),
	  int ($opt{a_incr} // ($a_op == BLAS_NO_TRANS ? $k : $m)),
	  $b,
	  int ($opt{b_ind} // 0),
	  int ($opt{b_incr} // ($b_op == BLAS_NO_TRANS ? $n : $k)),
	  $opt{beta} // 0,
	  $c,
	  int ($opt{c_ind} // 0),
	  int ($opt{c_incr} // $n));
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Math::BLAS - basic linear algebra subroutines


=head1 SYNOPSIS

    use Math::BLAS;


=head1 DESCRIPTION


=head2 General Conventions


=head3 Notation

The following notation is used in this document.

=over

=item *

I<A>, I<B>, and I<C> are matrices

=item *

I<D> is a diagonal matrix

=item *

I<P> is a permutation matrix

=item *

op(I<A>) denotes I<A> or I<A>'

=item *

I<A>' is the transpose matrix of I<A>

=item *

I<u>, I<v>, I<w>, I<x>, I<y>, and I<z> are vectors

=item *

I<r>, I<s>, and I<t> are scalars

=item *

α and β are constants

=item *

← denotes assignment

=back


=head3 Subroutine Arguments

=over

=item Problem Size

The problem size is specified by the integral numbers I<m> and I<n>.
For vector operations, argument I<n> is the number of vector elements.
For matrix operations, I<m> is the number of matrix rows and I<n> is the
number of matrix columns.  For square matrix operations, I<n> is the
number of matrix rows and matrix columns.

Size arguments which are not integral numbers are truncated to the next
integral number using Perl's built-in procedure C<int>.

=item Scalar Operands

A scalar operand is a Perl scalar value.  Scalar operands are specified
as properties with appropriate default values.

=item Vector Operands

A vector operand I<x> is specified by three arguments.  Required
argument I<x> is a Perl array reference.  The corresponding array index
property I<x_ind> specifies the Perl array index of the first vector
element.  The default value for the array index property is zero.
Vectors are permitted to have spacing between elements.  This spacing is
specified by the Perl array index increment property I<x_incr>.  The
default value for the array index increment property is one.

=item Matrix Operands

A matrix operand I<A> is specified by three arguments.  Required
argument I<a> is a Perl array reference.  The corresponding array index
property I<a_ind> specifies the Perl array index of the first matrix
element.  The default value for the array index property is zero.
Matrices are permitted to have more rows and/or columns than specified
by the problem size.  The actual number of columns is specified by the
Perl array index increment property I<a_incr>.  The default value for
the array index increment property is derived from the problem size.

=back


=head2 Reduction Operations

=over

=item C<blas_dot> (I<n>, I<x>, I<y>, ...)

Dot product.

=over

=item

I<r> ← α I<x>'·I<y> + β I<r>

=back

The C<dot> function adds the scaled dot product of two vectors I<x> and
I<y> into a scaled scalar I<r>.

=over

=item *

First argument I<n> is the number of vector elements.

=item *

Second argument I<x> is the left-hand side vector operand.

=item *

Third argument I<y> is the right-hand side vector operand.

=item *

The rest of the arguments form a property list.  Applicable standard
properties are I<x_ind>, I<x_incr>, I<y_ind>, and I<y_incr>.  The
following table lists the non-standard property names together with
their meaning.

=over

=item I<alpha>

The scale factor for the dot product.
Default value is one.

=item I<beta>

The scale factor for the scalar operand.
Default value is zero.

=item I<r>

The scalar operand.  Value is either a scalar value or an array
reference.  Default value is zero.

=item I<r_ind>

The Perl array index of the array element for the array I<r>.  This
property is only evaluated if I<r> is an array reference.  Default value
is zero.

=back

=back

Arguments I<x> and I<y> are only evaluated if I<alpha> is not equal to
zero and if I<n> is greater than zero.  Argument I<r> is only evaluated
if I<beta> is not equal to zero.

Return value is the result of the form.  If I<n> is less than zero, the
function returns immediately with a return value of C<undef>.


=item C<blas_norm> (I<n>, I<x>, ...)

Vector norms.

=over

=item one-norm

I<r> ← ∑ |x|

=item two-norm

I<r>² ← ∑ x²

=item infinity-norm

I<r> ← max |x|

=back

The C<norm> function computes either the one-norm, two-norm (that is
Euclidean norm), or infinity-norm of a vector I<x>.

=over

=item *

First argument I<n> is the number of vector elements.

=item *

Second argument I<x> is the vector operand.

=item *

The rest of the arguments form a property list.  Applicable standard
properties are I<x_ind> and I<x_incr>.  The following table lists the
non-standard property names together with their meaning.

=over

=item I<norm>

The type of vector norm.  Value is either C<BLAS_ONE_NORM>,
C<BLAS_TWO_NORM> (or C<BLAS_FROBENIUS_NORM>), or C<BLAS_INF_NORM>.
Default is to compute the one-norm.

=back

=back

Argument I<x> is only evaluated if I<n> is greater than zero.

Return value is the vector norm.  If I<n> is less than or equal to zero,
the function returns immediately with a return value of zero.


=item C<blas_sum> (I<n>, I<x>, ...)

Sum of vector elements.

=over

=item

I<r> ← ∑ x

=back

The C<sum> function computes the sum of the elements of a vector I<x>.

=over

=item *

First argument I<n> is the number of vector elements.

=item *

Second argument I<x> is the vector operand.

=item *

The rest of the arguments form a property list.  Applicable standard
properties are I<x_ind> and I<x_incr>.

=back

Argument I<x> is only evaluated if I<n> is greater than zero.

Return value is the result of the form.  If I<n> is less than or equal
to zero, the function returns immediately with a return value of zero.


=item C<blas_min_val> (I<n>, I<x>, ...)

=item C<blas_amin_val> (I<n>, I<x>, ...)

=item C<blas_max_val> (I<n>, I<x>, ...)

=item C<blas_amax_val> (I<n>, I<x>, ...)

Minimum/maximum value and location.

=over

=item minimum value

I<k>, I<r> ← min x

=item minimum absolute value

I<k>, I<r> ← min |x|

=item maximum value

I<k>, I<r> ← max x

=item maximum absolute value

I<k>, I<r> ← max |x|

=back

The C<min_val> function finds the smallest element of a vector.  The
C<amin_val> function finds the smallest element of a vector with respect
to the absolute value.  The C<max_val> function finds the largest
element of a vector.  The C<amax_val> function finds the largest element
of a vector with respect to the absolute value.

=over

=item *

First argument I<n> is the number of vector elements.

=item *

Second argument I<x> is the vector operand.

=item *

The rest of the arguments form a property list.  Applicable standard
properties are I<x_ind> and I<x_incr>.

=back

Argument I<x> is only evaluated if I<n> is greater than zero.

Return value is a list with two elements.  First element is the index
offset of the vector element.  Second element is the value of the
corresponding vector element.  If argument I<n> is less than or equal to
zero, the function returns immediately with an index offset of C<undef>
and an element value of zero.

If you are only interested in one of the return values, either assign
the unwanted return value to C<undef> or directly subscribe the returned
list.  Say, for example

    (undef, $val) = blas_min_val ($n, $x);

or

    $val = (blas_min_val ($n, $x))[1];


=item C<blas_sumsq> (I<n>, I<x>, ...)

Sum of squares.

=over

=item

I<s>·I<t>² ← I<s>·I<t>² + ∑ x²

=back

The C<sumsq> function computes the scaled sum of squares I<s> and
the scale factor I<t>.

=over

=item *

First argument I<n> is the number of vector elements.

=item *

Second argument I<x> is the vector operand.

=item *

The rest of the arguments form a property list.  Applicable standard
properties are I<x_ind> and I<x_incr>.  The following table lists the
non-standard property names together with their meaning.

=over

=item I<sumsq>

The start value for the scaled sum of squares.
Default value is zero.

=item I<scale>

The start value for the scale factor.
Default value is one.

=back

=back

Arguments I<x>, I<sumsq>, and I<scale> are only evaluated if I<n> is
greater than zero.

Return value is a list with two elements.  First element is the scaled
sum of squares.  Second element is the scale factor.  If I<n> is less
than or equal to zero, the function returns immediately with the
unchanged values of I<sumsq> and I<scale>.

=back


=head2 Vector Operations

=over

=item C<blas_rscale> (I<n>, I<x>, ...)

Reciprocal scale.

=over

=item

I<x> ← I<x>/α

=back

The C<rscale> function divides the elements of the vector I<x> by the
real scalar α.  The scalar α is expected to be non-zero.

=over

=item *

First argument I<n> is the number of vector elements.

=item *

Second argument I<x> is the vector operand.

=item *

The rest of the arguments form a property list.  Applicable standard
properties are I<x_ind> and I<x_incr>.  The following table lists the
non-standard property names together with their meaning.

=over

=item I<alpha>

The reciprocal scale factor for the vector operand.
Default value is one.

=back

=back

Argument I<x> is only evaluated if I<alpha> is not equal to one.

The procedure returns immediately if I<n> is less than or equal to zero.


=item C<blas_axpby> (I<n>, I<x>, I<y>, ...)

Scaled vector accumulation.

=over

=item

I<y> ← α I<x> + β I<y>

=back

The C<axpby> function adds the scaled vector I<x> into the scaled vector
I<y>.

=over

=item *

First argument I<n> is the number of vector elements.

=item *

Second argument I<x> is the first vector operand.

=item *

Third argument I<y> is the second vector operand.

=item *

The rest of the arguments form a property list.  Applicable standard
properties are I<x_ind>, I<x_incr>, I<y_ind>, and I<y_incr>.  The
following table lists the non-standard property names together with
their meaning.

=over

=item I<alpha>

The scale factor for the first vector operand.
Default value is one.

=item I<beta>

The scale factor for the second vector operand.
Default value is one.

=back

=back

Argument I<x> is only evaluated if I<alpha> is not equal to zero.

The procedure returns immediately if I<n> is less than or equal to zero.


=item C<blas_waxpby> (I<n>, I<x>, I<y>, I<w>, ...)

Scaled vector addition.

=over

=item

I<w> ← α I<x> + β I<y>

=back

The C<waxpby> function adds two scaled vectors I<x> and I<y> and stores
the result in the vector I<w>.

=over

=item *

First argument I<n> is the number of vector elements.

=item *

Second argument I<x> is the first vector operand.

=item *

Third argument I<y> is the second vector operand.

=item *

Fourth argument I<w> is the result vector.

=item *

The rest of the arguments form a property list.  Applicable standard
properties are I<x_ind>, I<x_incr>, I<y_ind>, I<y_incr>, I<w_ind>, and
I<w_incr>.  The following table lists the non-standard property names
together with their meaning.

=over

=item I<alpha>

The scale factor for the first vector operand.
Default value is one.

=item I<beta>

The scale factor for the second vector operand.
Default value is one.

=back

=back

Argument I<x> is only evaluated if I<alpha> is not equal to zero.
Argument I<y> is only evaluated if I<beta> is not equal to zero.

The procedure returns immediately if I<n> is less than or equal to zero.

=back


=head2 Data Movement with Vectors

=over

=item C<blas_copy> (I<n>, I<x>, I<y>, ...)

Copy vector elements.

=over

=item

I<y> ← I<x>

=back

The C<copy> function assigns the elements of the vector I<x> to the
elements of the vector I<y>.

=over

=item *

First argument I<n> is the number of vector elements.

=item *

Second argument I<x> is the source vector.

=item *

Third argument I<y> is the destination vector.

=item *

The rest of the arguments form a property list.  Applicable standard
properties are I<x_ind>, I<x_incr>, I<y_ind>, and I<y_incr>.

=back

The procedure returns immediately if I<n> is less than or equal to zero.


=item C<blas_swap> (I<n>, I<x>, I<y>, ...)

Interchange vector elements.

=over

=item

I<y> ↔ I<x>

=back

The C<swap> function interchanges the elements of the vector I<x> with
the elements of the vector I<y>.

=over

=item *

First argument I<n> is the number of vector elements.

=item *

Second argument I<x> is the first vector operand.

=item *

Third argument I<y> is the second vector operand.

=item *

The rest of the arguments form a property list.  Applicable standard
properties are I<x_ind>, I<x_incr>, I<y_ind>, and I<y_incr>.

=back

The procedure returns immediately if I<n> is less than or equal to zero.

=back


=head2 Matrix/Vector Operations

=over

=item C<blas_gemv> (I<m>, I<n>, I<a>, I<x>, I<y>, ...)

General matrix/vector multiplication.

=over

=item

I<y> ← α op(I<A>)·I<x> + β I<y>

=back

The C<gemv> function multiplies the matrix I<A> with the
vector I<x> and adds the scaled product into the scaled vector I<y>.
If S<op(I<A>) = I<A>>, I<A> is a S<(I<m>, I<n>)> matrix.
If S<op(I<A>) = I<A>'>, I<A> is a S<(I<n>, I<m>)> matrix.
Operand I<x> is a vector with I<n> elements and I<y> is a vector with
I<m> elements.

=over

=item *

First argument I<m> is the number of matrix rows.

=item *

Second argument I<n> is the number of matrix columns.

=item *

Third argument I<a> is the matrix operand.

=item *

Fourth argument I<x> is the vector operand.

=item *

Fifth argument I<y> is the result vector.

=item *

The rest of the arguments form a property list.  Applicable standard
properties are I<a_ind>, I<a_incr>, I<x_ind>, I<x_incr>, I<y_ind>, and
I<y_incr>.  The following table lists the non-standard property names
together with their meaning.

=over

=item I<a_op>

The transpose flag for the matrix I<A>.  Value is either
C<BLAS_NO_TRANS> or C<BLAS_TRANS>.  Default is to not transpose the
matrix I<A>.

=item I<alpha>

The scale factor for the matrix/vector product.
Default value is one.

=item I<beta>

The scale factor for the result vector.
Default value is zero.

=back

=back

The procedure returns immediately if I<m> or I<n> is less than or equal
to zero.

=back


=head2 Matrix/Matrix Operations

=over

=item C<blas_gemm> (I<m>, I<n>, I<k>, I<a>, I<b>, I<c>, ...)

General matrix/matrix multiplication.

=over

=item

I<C> ← α op(I<A>)·op(I<B>) + β I<C>

=back

The C<gemm> function multiplies the matrix I<A> with the matrix I<B> and
adds the scaled product into the scaled S<(I<m>, I<n>)> matrix I<C>.
If S<op(I<A>) = I<A>>, I<A> is a S<(I<m>, I<k>)> matrix.
If S<op(I<A>) = I<A>'>, I<A> is a S<(I<k>, I<m>)> matrix.
If S<op(I<B>) = I<B>>, I<B> is a S<(I<k>, I<n>)> matrix.
If S<op(I<B>) = I<B>'>, I<B> is a S<(I<n>, I<k>)> matrix.

=over

=item *

First argument I<m> is the number of matrix rows.

=item *

Second argument I<n> is the number of matrix columns.

=item *

Third argument I<k> is the number of vector elements for the
matrix/matrix product.

=item *

Fourth argument I<a> is the left-hand side matrix operand.

=item *

Fifth argument I<b> is the right-hand side matrix operand.

=item *

Sixth argument I<c> is the result matrix.

=item *

The rest of the arguments form a property list.  Applicable standard
properties are I<a_ind>, I<a_incr>, I<b_ind>, I<b_incr>, I<c_ind>, and
I<c_incr>.  The following table lists the non-standard property names
together with their meaning.

=over

=item I<a_op>

The transpose flag for the matrix I<A>.  Value is either
C<BLAS_NO_TRANS> or C<BLAS_TRANS>.  Default is to not transpose the
matrix I<A>.

=item I<b_op>

The transpose flag for the matrix I<B>.  Value is either
C<BLAS_NO_TRANS> or C<BLAS_TRANS>.  Default is to not transpose the
matrix I<B>.

=item I<alpha>

The scale factor for the matrix/matrix product.
Default value is one.

=item I<beta>

The scale factor for the result matrix.
Default value is zero.

=back

=back

The procedure returns immediately if I<m> or I<n> is less than or equal
to zero.

=back


=head1 SEE ALSO

Math::BLAS::L<Enum|Math::BLAS::Enum>,
Math::BLAS::L<Legacy|Math::BLAS::Legacy>


=head2 External Links

L<http://www.netlib.org/blas/blast-forum/>


=head1 AUTHOR

Ralph Schleicher <rs@ralph-schleicher.de>

=cut

## Math/BLAS.pm ends here
