# NAME

Math::Matrix - multiply and invert matrices

# SYNOPSIS

    use Math::Matrix;

    # Generate a random 3-by-3 matrix.
    srand(time);
    $A = Math::Matrix -> new([rand, rand, rand],
                             [rand, rand, rand],
                             [rand, rand, rand]);
    $A -> print("A\n");

    # Append a fourth column to $A.
    $x = Math::Matrix -> new([rand, rand, rand]);
    $E = $A -> concat($x -> transpose);
    $E -> print("Equation system\n");

    # Compute the solution.
    $s = $E -> solve;
    $s -> print("Solutions s\n");

    # Verify that the solution equals $x.
    $A -> multiply($s) -> print("A*s\n");

# DESCRIPTION

This module implements various constructors and methods for creating and
manipulating matrices.

All methods return new objects, so, for example, `$X->add($Y)` does not
modify `$X`.

    $X -> add($Y);         # $X not modified; output is lost
    $X = $X -> add($Y);    # this works

Some operators are overloaded (see ["OVERLOADING"](#overloading)) and allow the operand to be
modified directly.

    $X = $X + $Y;          # this works
    $X += $Y;              # so does this

# METHODS

## Constructors

- new

    Constructor arguments are a list of references to arrays of the same length.
    The arrays are copied. The method returns **undef** in case of error.

        $a = Math::Matrix->new([rand,rand,rand],
                               [rand,rand,rand],
                               [rand,rand,rand]);

    If you call `new` with no input arguments, a zero filled matrix with identical
    dimensions is returned:

        $b = $a->new();     # $b is a zero matrix with the size of $a

- new\_identity

    Returns a new identity matrix.

        $a = Math::Matrix -> new(3);        # $a is a 3-by-3 identity matrix

- eye

    This is an alias for `new_identity`.

- clone

    Clones a matrix and returns the clone.

        $b = $a->clone;

- diagonal

    A constructor method that creates a diagonal matrix from a single list or array
    of numbers.

        $p = Math::Matrix->diagonal(1, 4, 4, 8);
        $q = Math::Matrix->diagonal([1, 4, 4, 8]);

    The matrix is zero filled except for the diagonal members, which take the
    values of the vector.

    The method returns **undef** in case of error.

- tridiagonal

    A constructor method that creates a matrix from vectors of numbers.

        $p = Math::Matrix->tridiagonal([1, 4, 4, 8]);
        $q = Math::Matrix->tridiagonal([1, 4, 4, 8], [9, 12, 15]);
        $r = Math::Matrix->tridiagonal([1, 4, 4, 8], [9, 12, 15], [4, 3, 2]);

    In the first case, the main diagonal takes the values of the vector, while both
    of the upper and lower diagonals's values are all set to one.

    In the second case, the main diagonal takes the values of the first vector,
    while the upper and lower diagonals are each set to the values of the second
    vector.

    In the third case, the main diagonal takes the values of the first vector,
    while the upper diagonal is set to the values of the second vector, and the
    lower diagonal is set to the values of the third vector.

    The method returns **undef** in case of error.

## Other methods

- size

    You can determine the dimensions of a matrix by calling:

        ($m, $n) = $a->size;

- concat

    Concatenate matrices horizontally. The matrices must have the same number or
    rows. The result is a new matrix or **undef** in case of error.

        $x = Math::Matrix -> new([1, 2], [4, 5]);   # 2-by-2 matrix
        $y = Math::Matrix -> new([3], [6]);         # 2-by-1 matrix
        $z = $x -> concat($y);                      # 2-by-3 matrix

- transpose

    Returns the transposed matrix. This is the matrix where colums and rows of the
    argument matrix are swapped.

- negative

    Negate a matrix and return it.

        $a = Math::Matrix -> new([-2, 3]);
        $b = $a -> negative();                  # $b = [[2, -3]]

- multiply

    Multiplies two matrices where the length of the rows in the first matrix is the
    same as the length of the columns in the second matrix. Returns the product or
    **undef** in case of error.

- solve

    Solves a equation system given by the matrix. The number of colums must be
    greater than the number of rows. If variables are dependent from each other,
    the second and all further of the dependent coefficients are 0. This means the
    method can handle such systems. The method returns a matrix containing the
    solutions in its columns or **undef** in case of error.

- invert

    Invert a Matrix using `solve`.

- pinvert

    Compute the pseudo-inverse of the matrix: ((A'A)^-1)A'

- multiply\_scalar

    Multiplies a matrix and a scalar resulting in a matrix of the same dimensions
    with each element scaled with the scalar.

        $a->multiply_scalar(2);  scale matrix by factor 2

- add

    Add two matrices of the same dimensions.

- subtract

    Shorthand for `add($other->negative)`

- equal

    Decide if two matrices are equal. The criterion is, that each pair of elements
    differs less than $Math::Matrix::eps.

- slice

    Extract columns:

        a->slice(1,3,5);

- diagonal\_vector

    Extract the diagonal as an array:

        $diag = $a->diagonal_vector;

- tridiagonal\_vector

    Extract the diagonals that make up a tridiagonal matrix:

        ($main_d, $upper_d, $lower_d) = $a->tridiagonal_vector;

- determinant

    Compute the determinant of a matrix.

        $a = Math::Matrix->new([3, 1],
                               [4, 2]);
        $d = $a->determinant;                   # $d = 2

- dot\_product

    Compute the dot product of two vectors. The second operand does not have to be
    an object.

        # $x and $y are both objects
        $x = Math::Matrix -> new([1, 2, 3]);
        $y = Math::Matrix -> new([4, 5, 6]);
        $p = $x -> dot_product($y);             # $p = 32

        # Only $x is an object.
        $p = $x -> dot_product([4, 5, 6]);      # $p = 32

- absolute

    Compute the absolute value (i.e., length) of a vector.

        $v = Math::Matrix -> new([3, 4]);
        $a = $v -> absolute();                  # $v = 5

- normalize

    Normalize a vector, i.e., scale a vector so its length becomes 1.

        $v = Math::Matrix -> new([3, 4]);
        $u = $v -> normalize();                 # $u = [ 0.6, 0.8 ]

- cross\_product

    Compute the cross-product of vectors.

        $x = Math::Matrix -> new([1,3,2],
                                 [5,4,2]);
        $p = $x -> cross_product();             # $p = [ -2, 8, -11 ]

- as\_string

    Creates a string representation of the matrix and returns it.

        $x = Math::Matrix -> new([1, 2], [3, 4]);
        $s = $x -> as_string();

- print

    Prints the matrix on STDOUT. If the method has additional parameters, these are
    printed before the matrix is printed.

# OVERLOADING

The following operators are overloaded.

- `+` and `+=`

    Matrix addition. The two operands must have the same size.

        $C  = $A + $B;      # assign $A + $B to $C
        $A += $B;           # assign $A + $B to $A

- `-` and `-=`

    Matrix subtraction. The two operands must have the same size.

        $C  = $A + $B;      # assign $A - $B to $C
        $A += $B;           # assign $A - $B to $A

- `*` and `*=`

    Matrix multiplication. The number of columns in the first operand must be equal
    to the number of rows in the second operand.

        $C  = $A * $B;      # assign $A * $B to $C
        $A *= $B;           # assign $A * $B to $A

- `~`

    Transpose.

        $B = ~$A;           # $B is the transpose of $A

# BUGS

Please report any bugs through the web interface at
[https://rt.cpan.org/Ticket/Create.html?Queue=Math-Matrix](https://rt.cpan.org/Ticket/Create.html?Queue=Math-Matrix)
(requires login). We will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Matrix

You can also look for information at:

- GitHub Source Repository

    [https://github.com/pjacklam/p5-Math-Matrix](https://github.com/pjacklam/p5-Math-Matrix)

- RT: CPAN's request tracker

    [https://rt.cpan.org/Public/Dist/Display.html?Name=Math-Matrix](https://rt.cpan.org/Public/Dist/Display.html?Name=Math-Matrix)

- CPAN Ratings

    [https://cpanratings.perl.org/dist/Math-Matrix](https://cpanratings.perl.org/dist/Math-Matrix)

- MetaCPAN

    [https://metacpan.org/release/Math-Matrix](https://metacpan.org/release/Math-Matrix)

- CPAN Testers Matrix

    [http://matrix.cpantesters.org/?dist=Math-Matrix](http://matrix.cpantesters.org/?dist=Math-Matrix)

# LICENSE AND COPYRIGHT

Copyright (c) 2020, Peter John Acklam.

Copyright (C) 2013, John M. Gamble <jgamble@ripco.com>, all rights reserved.

Copyright (C) 2009, oshalla
https://rt.cpan.org/Public/Bug/Display.html?id=42919

Copyright (C) 2002, Bill Denney <gte273i@prism.gatech.edu>, all rights
reserved.

Copyright (C) 2001, Brian J. Watson <bjbrew@power.net>, all rights reserved.

Copyright (C) 2001, Ulrich Pfeifer <pfeifer@wait.de>, all rights reserved.
Copyright (C) 1995, Universität Dortmund, all rights reserved.

Copyright (C) 2001, Matthew Brett <matthew.brett@mrc-cbu.cam.ac.uk>

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

# AUTHORS

Peter John Acklam <pjacklam@gmail.com> (2020)

Ulrich Pfeifer <pfeifer@ls6.informatik.uni-dortmund.de> (1995-2013)

Brian J. Watson <bjbrew@power.net>

Matthew Brett <matthew.brett@mrc-cbu.cam.ac.uk>
