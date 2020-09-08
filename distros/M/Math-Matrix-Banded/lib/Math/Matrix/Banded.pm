package Math::Matrix::Banded;
use 5.014;

=pod

=head1 NAME

Math::Matrix::Banded - non-zero entries confined to a diagonal band

=head1 VERSION

Version 0.004

=cut

our $VERSION = '0.004';

use Math::Matrix::Banded::Square;
use Math::Matrix::Banded::Rectangular;


sub new {
    my ($class, %args) = @_;

    if (!exists($args{M}) and exists($args{N})) {
        return Math::Matrix::Banded::Square->new(%args);
    }
    else {
        return Math::Matrix::Banded::Rectangular->new(%args);
    }
}


1;

__END__

=pod

=head1 SYNOPSIS

    use Math::Matrix::Banded;

    my $matrix = Math::Matrix::Banded->new(N => 7);
    $matrix->element(0, 0, 5);
    $matrix->element(4, 5, -1);
    # ...

    $matrix->decompose_LU;
    my $x = $matrix->solve_LU([0, 2, 4, 5, 3, 6, -2]);


=head1 DESCRIPTION

A banded matrix (or band matrix or band diagonal matrix) is a matrix
whose non-zero columns are confined to a diagonal band. Obviously,
such a structure allows for more efficient storage and computation
than for a general matrix.

CAVEAT: This is a young distribution. It currently focuses on the
functionality that I need myself. If you miss certain features,
please let me know and I will consider prioritizing them for future
releases.


=head2 General Remarks

=over 4

=item * Row and column indices start at 0. This might require extra
attention since in most mathematics texts, they start at 1.

=item * In order to exploit the bandedness of your matrix, you must
not set off-band elements even if they are 0. The L<element|element>
method adjusts the band structure of the stored matrix no matter
what the value is.

=item * Currently, no operators are overloaded. This will probably
change in the future in order to at least use C<*> in the natural
way.

=back


=head3 Constructor Dispatch

This distribution supports both square and non-square matrices. They
a stored in different data structures and offer different
functionality and are therefore implemented in separate classes. The
constructors of C<Math::Matrix::Banded> dispatch to constructors of
L<Math::Matrix::Banded::Square|Math::Matrix::Banded::Square> and
L<Math::Matrix::Banded::Rectangular|Math::Matrix::Banded::Rectangular>,
respectively.


=head2 Square Matrices

An NxN matrix A = (a_ij) is a band matrix with lower bandwidth
m_below and upper bandwidth m_above if a_ij = 0 for all
j < i - m_below and all j > i + m_above. (If you phrase it like this
then it might seem more appropriate to speak of left and right
bandwidths instead of lower and upper, but the latter are the
accepted terms).

According to the above definition, every matrix can be considered as
a banded matrix, and this distribution does indeed support arbitrary
matrices. However, it only makes sense to treat a matrix as banded
if m_below and m_above are much smaller than N.


=head2 Symmetric Matrices

Obviously, a symmetric banded matrix can be stored using even less
space than a generic banded matrix. Be aware that this potential is
B<not> exploited by the current implementation. If you set the
C<symmetric> flag (see below) this only leads to that a_ji is set
whenever you set a_ij. This might change in a future version.


=head2 Non-square matrices

For non-square matrices it is much less well defined in the
literature what a banded matrix is. In this distribution it means
that each row contains a non-zero block of entries and that start
and end of that block are non-decreasing from top to bottom of the
matrix. For example, this is a banded rectangular matrix:

    1 2 3 x x x x
    4 5 6 x x x x
    x 7 8 x x x x
    x x 9 1 x x x

Entries are stored as explicit zeroes to enforce this structure:

    1 2 3 x x x x
    4 5 6 x x x x
    x 7 0 x x x x
    x x 9 1 x x x

The 0 at C<(2, 2)> is stored even if it is not set explicitly.


=head1 CONSTRUCTORS

=head3 new

    $matrix = Math::Matrix::Banded->new(N => 7);
    $matrix = Math::Matrix::Banded->new(
        M => 7,
        N => 11,
    );

The constructor dispatches to the constructor of a square matrix iff
N is specified and M is not specified, otherwise it dispatches to
the constructor of a rectangular matrix.

B<Parameters:>

=over 4

=item N

The number of columns of the matrix. In case of a square matrix, this is
also the number of rows. This parameters is mandatory.

=item M

The number of rows of the matrix. This parameters is mandatory in
the case of a non-square matrix.

=item symmetric

Optional parameter for a square matrix to indicate that the matrix
is symmetric. Defaults to 0. If it is set to a true value then a_ji
is set whenever you set a_ij.

=item m_below

Optional parameter to initialize the lower bandwidth of a square
matrix. It is adapted as needed when elements are set.

=item m_above

Optional parameter to initialize the upper bandwidth of a square
matrix. It is adapted as needed when elements are set.

=back


=head1 ATTRIBUTES

=head2 Square Matrices

=head3 N

Readonly attribute storing the number of rows and columns of the
matrix.

=head3 m_below

Readonly attribute storing the lower bandwith of the matrix. It is
adapted as needed when elements are set.

=head3 m_above

Readonly attribute storing the upper bandwith of the matrix. It is
adapted as needed when elements are set.

=head3 symmetric

Readonly attribute storing whether the matrix was created as
symmetric.

=head3 L

Readonly attribute storing the lower diagonal part of the LU
decomposition of the matrix.

In the current implementation, the LU decomposition is calculated
automatically if this attribute is accessed and is not set. However,
this is considered experimental. It is recommended to call
L<decompose_LU|decompose_LU> explicitly before accessing this
attribute.

=head3 U

Readonly attribute storing the upper diagonal part of the LU
decomposition of the matrix.

In the current implementation, the LU decomposition is calculated
automatically if this attribute is accessed and is not set. However,
this is considered experimental. It is recommended to call
L<decompose_LU|decompose_LU> explicitly before accessing this
attribute.


=head2 Rectangular Matrices

=head3 M

Readonly attribute storing the number of rows of the matrix.

=head3 N

Readonly attribute storing the number of columns of the matrix.


=head1 METHODS

=head2 Methods common to square and rectangular Matrices

=head3 element

    $matrix->element(0, 1, -5);
    $a = $matrix->element(4, 0);

Sets/gets an element of the matrix. Row and column indices start at
0. The band structure of the matrix is maintained automatically when
setting elements.


=head3 row

    $row = $matrix->row(0);

Returns the specified row as an array reference. The array is a
copy, modifying it will not affect the matrix. This method is mostly
meant for debugging purposes because the returned row includes all
the vanishing elements that you typically want to skip by using a
banded matrix.


=head3 column

    $column = $matrix->column(0);

Returns the specified column as an array reference. The array is a
copy, modifying it will not affect the matrix. This method is mostly
meant for debugging purposes because the returned column includes
all the vanishing elements that you typically want to skip by using
a banded matrix.


=head3 as_string

Returns a string representation of the matrix including all
elements. This is for debugging purposes and the exact format might
change in the future.


=head3 multiply_vector

    $w = $A->multiply_vector([1, 2, 3]);

Expects a vector v as an array reference with L<N|N> components and
returns Av as an array reference.


=head2 Square Matrices

=head3 multiply_matrix

    $C = $A->multiply_matrix($B);

Expects another banded square matrix B of the same size and returns
AB. The input matrices remain unchanged. The lower (upper) bandwidth
of the resulting matrix is the sum of the lower (upper) bandwidths
of A and B.

CAVEAT: Obviously, it would make mathematical sense to provide a
rectangular matrix with N rows and get a rectangular matrix
back. However, this is currently not implemented.


=head3 decompose_LU

    $success = $A->decompose_LU

Computes the LU decomposition of the matrix without
pivoting. Returns 1 on success and undef on failure.

CAVEAT: Be aware that LU decomposition can be numerically unstable
or even fail even if the matrix is non-singular. It is only safe to
use this method if you know that LU decomposition without pivoting
can be used safely on your matrix (e.g. if your matrix is strictly
diagonally dominant).

CAVEAT: The LU decomposition is not reset if you change the matrix
afterwards by calling the L<element|element> method. I do not want
to call the clearer on every call of L<element|element>. It is
recommended to set all elements before doing anything else. If you
cannot ensure that then make sure to call decompose_LU explicitly
before using the LU decompositon.

Remark: Straight-forward pivoting destroys the band structure on a
matrix, hence it is more complicated to implement than
usual. Partial pivoting might be added in a future version of this
module.


=head3 solve_LU

    my $x = $A->solve_LU($y);

Expects a vector y as an array reference with L<N|N> components.
Uses the LU decomposition of A to determine the solution of the
equation system Ax = y. The LU decomposition is computed if that has
not happened before. Returns x as array reference or undef if no
solution could be computed. See also L<decompose_LU|decompose_LU>.


=head3 Non-square Matrices

=head3 transpose

    $At = $A->transpose

Returns the transposed matrix.


=head3 AAt

    $AAt = $A->AAt

Returns the square symmetric NxN matrix that results from
multiplying A with its own transpose.


=head3 AtA

    $AtA = $A->AtA

Returns the square symmetric MxM matrix that results from
multiplying the transpose of A with A. It is identical to

    $AtA = $A->transpose->AAt


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-matrix-banded at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Matrix-Banded>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Lutz Gehlen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)
