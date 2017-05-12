## Math/BLAS/Enum.pm --- named constants.

# Copyright (C) 2010 Ralph Schleicher.  All rights reserved.

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

## Code:

package Math::BLAS::Enum;

use strict;
use warnings;
use Exporter qw(import);

BEGIN
{
  our $VERSION = '1.01';
  our @EXPORT = ();
  our @EXPORT_OK = ();
  our %EXPORT_TAGS = ();

  $EXPORT_TAGS{order}
    = [qw(BLAS_ROWMAJOR
	  BLAS_COLMAJOR)];
  push (@EXPORT_OK, @{ $EXPORT_TAGS{order} });

  $EXPORT_TAGS{trans}
    = [qw(BLAS_NO_TRANS
	  BLAS_TRANS
	  BLAS_CONJ_TRANS)];
  push (@EXPORT_OK, @{ $EXPORT_TAGS{trans} });
  push (@EXPORT, @{ $EXPORT_TAGS{trans} });

  $EXPORT_TAGS{uplo}
    = [qw(BLAS_UPPER
	  BLAS_LOWER)];
  push (@EXPORT_OK, @{ $EXPORT_TAGS{uplo} });

  $EXPORT_TAGS{diag}
    = [qw(BLAS_NON_UNIT_DIAG
	  BLAS_UNIT_DIAG)];
  push (@EXPORT_OK, @{ $EXPORT_TAGS{diag} });

  $EXPORT_TAGS{side}
    = [qw(BLAS_LEFT_SIDE
	  BLAS_RIGHT_SIDE)];
  push (@EXPORT_OK, @{ $EXPORT_TAGS{side} });

  $EXPORT_TAGS{cmach}
    = [qw(BLAS_BASE
	  BLAS_T
	  BLAS_RND
	  BLAS_IEEE
	  BLAS_EMIN
	  BLAS_EMAX
	  BLAS_EPS
	  BLAS_PREC
	  BLAS_UNDERFLOW
	  BLAS_OVERFLOW
	  BLAS_SFMIN)];
  push (@EXPORT_OK, @{ $EXPORT_TAGS{cmach} });

  $EXPORT_TAGS{norm}
    = [qw(BLAS_ONE_NORM
	  BLAS_REAL_ONE_NORM
	  BLAS_TWO_NORM
	  BLAS_FROBENIUS_NORM
	  BLAS_INF_NORM
	  BLAS_REAL_INF_NORM
	  BLAS_MAX_NORM
	  BLAS_REAL_MAX_NORM)];
  push (@EXPORT_OK, @{ $EXPORT_TAGS{norm} });
  push (@EXPORT, @{ $EXPORT_TAGS{norm} });

  $EXPORT_TAGS{sort}
    = [qw(BLAS_INCREASING_ORDER
	  BLAS_DECREASING_ORDER)];
  push (@EXPORT_OK, @{ $EXPORT_TAGS{sort} });

  $EXPORT_TAGS{conj}
    = [qw(BLAS_CONJ
	  BLAS_NO_CONJ)];
  push (@EXPORT_OK, @{ $EXPORT_TAGS{conj} });

  $EXPORT_TAGS{jrot}
    = [qw(BLAS_JROT_INNER
	  BLAS_JROT_OUTER
	  BLAS_JROT_SORTED)];
  push (@EXPORT_OK, @{ $EXPORT_TAGS{jrot} });

  $EXPORT_TAGS{prec}
    = [qw(BLAS_PREC_SINGLE
	  BLAS_PREC_DOUBLE
	  BLAS_PREC_INDIGENOUS
	  BLAS_PREC_EXTRA)];
  push (@EXPORT_OK, @{ $EXPORT_TAGS{prec} });

  $EXPORT_TAGS{base}
    = [qw(BLAS_ZERO_BASE
	  BLAS_ONE_BASE)];
  push (@EXPORT_OK, @{ $EXPORT_TAGS{base} });

  $EXPORT_TAGS{symmetry}
    = [qw(BLAS_GENERAL
	  BLAS_SYMMETRIC
	  BLAS_HERMITIAN
	  BLAS_TRIANGULAR
	  BLAS_LOWER_TRIANGULAR
	  BLAS_UPPER_TRIANGULAR
	  BLAS_LOWER_SYMMETRIC
	  BLAS_UPPER_SYMMETRIC
	  BLAS_LOWER_HERMITIAN
	  BLAS_UPPER_HERMITIAN)];
  push (@EXPORT_OK, @{ $EXPORT_TAGS{symmetry} });

  $EXPORT_TAGS{field}
    = [qw(BLAS_COMPLEX
	  BLAS_REAL
	  BLAS_DOUBLE_PRECISION
	  BLAS_SINGLE_PRECISION)];
  push (@EXPORT_OK, @{ $EXPORT_TAGS{field} });

  $EXPORT_TAGS{size}
    = [qw(BLAS_NUM_ROWS
	  BLAS_NUM_COLS
	  BLAS_NUM_NONZEROS)];
  push (@EXPORT_OK, @{ $EXPORT_TAGS{size} });

  $EXPORT_TAGS{handle}
    = [qw(BLAS_INVALID_HANDLE
	  BLAS_NEW_HANDLE
	  BLAS_OPEN_HANDLE
	  BLAS_VALID_HANDLE)];
  push (@EXPORT_OK, @{ $EXPORT_TAGS{handle} });

  $EXPORT_TAGS{sparsity_optimization}
    = [qw(BLAS_REGULAR
	  BLAS_IRREGULAR
	  BLAS_BLOCK
	  BLAS_UNASSEMBLED)];
  push (@EXPORT_OK, @{ $EXPORT_TAGS{sparsity_optimization} });

  $EXPORT_TAGS{all} = [ @EXPORT_OK ];
}

sub BLAS_ROWMAJOR () { 101 }
sub BLAS_COLMAJOR () { 102 }
sub BLAS_NO_TRANS () { 111 }
sub BLAS_TRANS () { 112 }
sub BLAS_CONJ_TRANS () { 113 }
sub BLAS_UPPER () { 121 }
sub BLAS_LOWER () { 122 }
sub BLAS_NON_UNIT_DIAG () { 131 }
sub BLAS_UNIT_DIAG () { 132 }
sub BLAS_LEFT_SIDE () { 141 }
sub BLAS_RIGHT_SIDE () { 142 }
sub BLAS_BASE () { 151 }
sub BLAS_T () { 152 }
sub BLAS_RND () { 153 }
sub BLAS_IEEE () { 154 }
sub BLAS_EMIN () { 155 }
sub BLAS_EMAX () { 156 }
sub BLAS_EPS () { 157 }
sub BLAS_PREC () { 158 }
sub BLAS_UNDERFLOW () { 159 }
sub BLAS_OVERFLOW () { 160 }
sub BLAS_SFMIN () { 161}
sub BLAS_ONE_NORM () { 171 }
sub BLAS_REAL_ONE_NORM () { 172 }
sub BLAS_TWO_NORM () { 173 }
sub BLAS_FROBENIUS_NORM () { 174 }
sub BLAS_INF_NORM () { 175 }
sub BLAS_REAL_INF_NORM () { 176 }
sub BLAS_MAX_NORM () { 177 }
sub BLAS_REAL_MAX_NORM () { 178 }
sub BLAS_INCREASING_ORDER () { 181 }
sub BLAS_DECREASING_ORDER () { 182 }
sub BLAS_CONJ () { 191 }
sub BLAS_NO_CONJ () { 192 }
sub BLAS_JROT_INNER () { 201 }
sub BLAS_JROT_OUTER () { 202 }
sub BLAS_JROT_SORTED () { 203 }
sub BLAS_PREC_SINGLE () { 211 }
sub BLAS_PREC_DOUBLE () { 212 }
sub BLAS_PREC_INDIGENOUS () { 213 }
sub BLAS_PREC_EXTRA () { 214 }
sub BLAS_ZERO_BASE () { 221 }
sub BLAS_ONE_BASE () { 222 }
sub BLAS_GENERAL () { 231 }
sub BLAS_SYMMETRIC () { 232 }
sub BLAS_HERMITIAN () { 233 }
sub BLAS_TRIANGULAR () { 234 }
sub BLAS_LOWER_TRIANGULAR () { 235 }
sub BLAS_UPPER_TRIANGULAR () { 236 }
sub BLAS_LOWER_SYMMETRIC () { 237 }
sub BLAS_UPPER_SYMMETRIC () { 238 }
sub BLAS_LOWER_HERMITIAN () { 239 }
sub BLAS_UPPER_HERMITIAN () { 240 }
sub BLAS_COMPLEX () { 241 }
sub BLAS_REAL () { 242 }
sub BLAS_DOUBLE_PRECISION () { 243 }
sub BLAS_SINGLE_PRECISION () { 244 }
sub BLAS_NUM_ROWS () { 251 }
sub BLAS_NUM_COLS () { 252 }
sub BLAS_NUM_NONZEROS () { 253 }
sub BLAS_INVALID_HANDLE () { 261 }
sub BLAS_NEW_HANDLE () { 262 }
sub BLAS_OPEN_HANDLE () { 263 }
sub BLAS_VALID_HANDLE () { 264}
sub BLAS_REGULAR () { 271 }
sub BLAS_IRREGULAR () { 272 }
sub BLAS_BLOCK () { 273 }
sub BLAS_UNASSEMBLED () { 274 }

1;

__END__

=pod

=encoding utf8

=head1 NAME

Math::BLAS::Enum - named constants


=head1 SYNOPSIS

    use Math::BLAS::Enum;


=head1 DESCRIPTION

Default is to export all constants actually used in the implementation.


=head2 Matrix Ordering

The constants in this group can be imported via the C<:order> tag.

=over

=item C<BLAS_ROWMAJOR>

matrix elements are stored in row-major order (default for Perl)

=item C<BLAS_COLMAJOR>

matrix elements are stored in column-major order

=back


=head2 Matrix Operations

The constants in this group can be imported via the C<:trans> tag.

=over

=item C<BLAS_NO_TRANS>

operate with the matrix (default)

=item C<BLAS_TRANS>

operate with the transpose matrix

=item C<BLAS_CONJ_TRANS>

operate with the conjugate transpose matrix

=back


=head2 Triangular Matrices

The constants in this group can be imported via the C<:uplo> tag.

=over

=item C<BLAS_UPPER>

refer to upper triangular matrix (default)

=item C<BLAS_LOWER>

refer to lower triangular matrix

=back

The constants in this group can be imported via the C<:diag> tag.

=over

=item C<BLAS_NON_UNIT_DIAG>

non-unit triangular matrix (default)

=item C<BLAS_UNIT_DIAG>

unit triangular matrix, that is diagonal matrix elements are assumed to
be one

=back


=head2 Operation Side

The constants in this group can be imported via the C<:side> tag.

=over

=item C<BLAS_LEFT_SIDE>

operate on the left-hand side (default)

=item C<BLAS_RIGHT_SIDE>

operate on the right-hand side

=back


=head2 Vector and Matrix Norms

The constants in this group can be imported via the C<:norm> tag.

=over

=item C<BLAS_ONE_NORM>

one-norm (default)

=item C<BLAS_REAL_ONE_NORM>

real one-norm

=item C<BLAS_TWO_NORM>

two-norm

=item C<BLAS_FROBENIUS_NORM>

Frobenius-norm

=item C<BLAS_INF_NORM>

infinity-norm

=item C<BLAS_REAL_INF_NORM>

real infinity-norm

=item C<BLAS_MAX_NORM>

maximum-norm

=item C<BLAS_REAL_MAX_NORM>

real maximum-norm

=back


=head2 Sorting Order

The constants in this group can be imported via the C<:sort> tag.

=over

=item C<BLAS_INCREASING_ORDER>

sort in increasing order (default)

=item C<BLAS_DECREASING_ORDER>

sort in decreasing order

=back


=head2 Complex Matrix Elements

The constants in this group can be imported via the C<:conj> tag.

=over

=item C<BLAS_NO_CONJ>

operate with the complex vector (default)

=item C<BLAS_CONJ>

operate with the conjugate of the complex vector

=back


=head2 Jacobi Rotations

The constants in this group can be imported via the C<:jrot> tag.

=over

=item C<BLAS_JROT_INNER>

inner rotation (default)

=item C<BLAS_JROT_OUTER>

outer rotation

=item C<BLAS_JROT_SORTED>

sorted rotation

=back


=head2 Index Base

The constants in this group can be imported via the C<:base> tag.

=over

=item C<BLAS_ZERO_BASE>

indices are zero-based (default for Perl)

=item C<BLAS_ONE_BASE>

indices are one-based

=back


=head2 Symmetric Matrices

The constants in this group can be imported via the C<:symmetry> tag.

=over

=item C<BLAS_GENERAL>

general matrix (default)

=item C<BLAS_SYMMETRIC>

symmetric matrix

=item C<BLAS_HERMITIAN>

Hermitian matrix

=item C<BLAS_TRIANGULAR>

triangular matrix

=item C<BLAS_LOWER_TRIANGULAR>

lower triangular matrix

=item C<BLAS_UPPER_TRIANGULAR>

upper triangular matrix

=item C<BLAS_LOWER_SYMMETRIC>

only the lower half of a symmetric matrix is specified

=item C<BLAS_UPPER_SYMMETRIC>

only the upper half of a symmetric matrix is specified

=item C<BLAS_LOWER_HERMITIAN>

only the lower half of a Hermitian matrix is specified

=item C<BLAS_UPPER_HERMITIAN>

only the upper half of a Hermitian matrix is specified

=back


=head1 AUTHOR

Ralph Schleicher <rs@ralph-schleicher.de>

=cut

## Math/BLAS/Enum.pm ends here
