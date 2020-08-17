# -*- mode: perl; coding: utf-8-unix -*-

=pod

=encoding utf8

=head1 NAME

Math::Matrix - multiply and invert matrices

=head1 SYNOPSIS

    use Math::Matrix;

    # Generate a random 3-by-3 matrix.
    srand(time);
    my $A = Math::Matrix -> new([rand, rand, rand],
                                [rand, rand, rand],
                                [rand, rand, rand]);
    $A -> print("A\n");

    # Append a fourth column to $A.
    my $x = Math::Matrix -> new([rand, rand, rand]);
    my $E = $A -> concat($x -> transpose);
    $E -> print("Equation system\n");

    # Compute the solution.
    my $s = $E -> solve;
    $s -> print("Solutions s\n");

    # Verify that the solution equals $x.
    $A -> multiply($s) -> print("A*s\n");

=head1 DESCRIPTION

This module implements various constructors and methods for creating and
manipulating matrices.

All methods return new objects, so, for example, C<$X-E<gt>add($Y)> does not
modify C<$X>.

    $X -> add($Y);         # $X not modified; output is lost
    $X = $X -> add($Y);    # this works

Some operators are overloaded (see L</OVERLOADING>) and allow the operand to be
modified directly.

    $X = $X + $Y;          # this works
    $X += $Y;              # so does this

=head1 METHODS

=head2 Constructors

=over

=item new()

Creates a new object from the input arguments and returns it.

If a single input argument is given, and that argument is a reference to array
whose first element is itself a reference to an array, it is assumed that the
argument contains the whole matrix, like this:

    $x = Math::Matrix->new([[1, 2, 3], [4, 5, 6]]); # 2-by-3 matrix
    $x = Math::Matrix->new([[1, 2, 3]]);            # 1-by-3 matrix
    $x = Math::Matrix->new([[1], [2], [3]]);        # 3-by-1 matrix

If a single input argument is given, and that argument is not a reference to an
array, a 1-by-1 matrix is returned.

    $x = Math::Matrix->new(1);                      # 1-by-1 matrix

Otherwise it is assumed that each input argument is a row, like this:

    $x = Math::Matrix->new([1, 2, 3], [4, 5, 6]);   # 2-by-3 matrix
    $x = Math::Matrix->new([1, 2, 3]);              # 1-by-3 matrix
    $x = Math::Matrix->new([1], [2], [3]);          # 3-by-1 matrix

Note that all the folling cases result in an empty matrix:

    $x = Math::Matrix->new([[], [], []]);
    $x = Math::Matrix->new([[]]);
    $x = Math::Matrix->new([]);

If C<new> is called as an instance method with no input arguments, a zero
filled matrix with identical dimensions is returned:

    $b = $a->new();     # $b is a zero matrix with the size of $a

Each row must contain the same number of elements.

In case of an erry, B<undef> is returned.

=item new_identity()

Returns a new identity matrix.

    $a = Math::Matrix -> new(3);        # $a is a 3-by-3 identity matrix

=item eye()

This is an alias for C<new_identity>.

=item clone()

Clones a matrix and returns the clone.

    $b = $a->clone;

=item diagonal()

A constructor method that creates a diagonal matrix from a single list or array
of numbers.

    $p = Math::Matrix->diagonal(1, 4, 4, 8);
    $q = Math::Matrix->diagonal([1, 4, 4, 8]);

The matrix is zero filled except for the diagonal members, which take the
values of the vector.

The method returns B<undef> in case of error.

=item tridiagonal()

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

The method returns B<undef> in case of error.

=back

=head2 Other methods

=over

=item size()

You can determine the dimensions of a matrix by calling:

    ($m, $n) = $a->size;

=item concat()

Concatenate matrices horizontally. The matrices must have the same number or
rows. The result is a new matrix or B<undef> in case of error.

    $x = Math::Matrix -> new([1, 2], [4, 5]);   # 2-by-2 matrix
    $y = Math::Matrix -> new([3], [6]);         # 2-by-1 matrix
    $z = $x -> concat($y);                      # 2-by-3 matrix

=item transpose()

Returns the transposed matrix. This is the matrix where colums and rows of the
argument matrix are swapped.

=item negative()

Negate a matrix and return it.

    $a = Math::Matrix -> new([-2, 3]);
    $b = $a -> negative();                  # $b = [[2, -3]]

=item multiply()

Multiplies two matrices where the length of the rows in the first matrix is the
same as the length of the columns in the second matrix. Returns the product or
B<undef> in case of error.

=item solve()

Solves a equation system given by the matrix. The number of colums must be
greater than the number of rows. If variables are dependent from each other,
the second and all further of the dependent coefficients are 0. This means the
method can handle such systems. The method returns a matrix containing the
solutions in its columns or B<undef> in case of error.

=item invert()

Invert a Matrix using C<solve>.

=item pinvert()

Compute the pseudo-inverse of the matrix: ((A'A)^-1)A'

=item multiply_scalar()

Multiplies a matrix and a scalar resulting in a matrix of the same dimensions
with each element scaled with the scalar.

    $a->multiply_scalar(2);  scale matrix by factor 2

=item add()

Add two matrices of the same dimensions.

=item subtract()

Shorthand for C<add($other-E<gt>negative)>

=item equal()

Decide if two matrices are equal. The criterion is, that each pair of elements
differs less than $Math::Matrix::eps.

=item slice()

Extract columns:

    a->slice(1,3,5);

=item diagonal_vector()

Extract the diagonal as an array:

    $diag = $a->diagonal_vector;

=item tridiagonal_vector()

Extract the diagonals that make up a tridiagonal matrix:

    ($main_d, $upper_d, $lower_d) = $a->tridiagonal_vector;

=item determinant()

Compute the determinant of a matrix.

    $a = Math::Matrix->new([3, 1],
                           [4, 2]);
    $d = $a->determinant;                   # $d = 2

=item dot_product()

Compute the dot product of two vectors. The second operand does not have to be
an object.

    # $x and $y are both objects
    $x = Math::Matrix -> new([1, 2, 3]);
    $y = Math::Matrix -> new([4, 5, 6]);
    $p = $x -> dot_product($y);             # $p = 32

    # Only $x is an object.
    $p = $x -> dot_product([4, 5, 6]);      # $p = 32

=item absolute()

Compute the absolute value (i.e., length) of a vector.

    $v = Math::Matrix -> new([3, 4]);
    $a = $v -> absolute();                  # $v = 5

=item normalize()

Normalize a vector, i.e., scale a vector so its length becomes 1.

    $v = Math::Matrix -> new([3, 4]);
    $u = $v -> normalize();                 # $u = [ 0.6, 0.8 ]

=item cross_product()

Compute the cross-product of vectors.

    $x = Math::Matrix -> new([1,3,2],
                             [5,4,2]);
    $p = $x -> cross_product();             # $p = [ -2, 8, -11 ]

=item as_string()

Creates a string representation of the matrix and returns it.

    $x = Math::Matrix -> new([1, 2], [3, 4]);
    $s = $x -> as_string();

=item print()

Prints the matrix on STDOUT. If the method has additional parameters, these are
printed before the matrix is printed.

=item version()

Returns a string contining the package name and version number.

=back

=head1 OVERLOADING

The following operators are overloaded.

=over

=item C<+> and C<+=>

Matrix addition. The two operands must have the same size.

    $C  = $A + $B;      # assign $A + $B to $C
    $A += $B;           # assign $A + $B to $A

=item C<-> and C<-=>

Matrix subtraction. The two operands must have the same size.

    $C  = $A + $B;      # assign $A - $B to $C
    $A += $B;           # assign $A - $B to $A

=item C<*> and C<*=>

Matrix multiplication. The number of columns in the first operand must be equal
to the number of rows in the second operand.

    $C  = $A * $B;      # assign $A * $B to $C
    $A *= $B;           # assign $A * $B to $A

=item C<~>

Transpose.

    $B = ~$A;           # $B is the transpose of $A

=back

=head1 BUGS

Please report any bugs through the web interface at
L<https://rt.cpan.org/Ticket/Create.html?Queue=Math-Matrix>
(requires login). We will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Matrix

You can also look for information at:

=over 4

=item * GitHub Source Repository

L<https://github.com/pjacklam/p5-Math-Matrix>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Math-Matrix>

=item * CPAN Ratings

L<https://cpanratings.perl.org/dist/Math-Matrix>

=item * MetaCPAN

L<https://metacpan.org/release/Math-Matrix>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Math-Matrix>

=back

=head1 LICENSE AND COPYRIGHT

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

=head1 AUTHORS

Peter John Acklam E<lt>pjacklam@gmail.comE<gt> (2020)

Ulrich Pfeifer E<lt>pfeifer@ls6.informatik.uni-dortmund.deE<gt> (1995-2013)

Brian J. Watson E<lt>bjbrew@power.netE<gt>

Matthew Brett E<lt>matthew.brett@mrc-cbu.cam.ac.ukE<gt>

=cut

package Math::Matrix;

use strict;
use warnings;

use Carp;

our $VERSION = '0.91';
our $eps = 0.00001;

use overload
  '+'  => 'add',
  '-'  => 'subtract',
  '*'  => 'multiply',
  '~'  => 'transpose',
  '""' => 'as_string',
  '='  => 'clone';

sub version {
    return "Math::Matrix $VERSION";
}

# Implement - array copy, inheritance

sub new {
    my $that = shift;
    my $class = ref($that) || $that;
    my $self = [];

    # If called as an instance method and no arguments are given, return a
    # zero matrix of the same size as the invocand.

    if (ref($that) && (@_ == 0)) {
        for (@$that) {
            push(@{$self}, [map {0} @{$_}]);
        }
    }

    # Otherwise return a new matrix based on the input arguments. The object
    # data is a blessed reference to an array containing the matrix data. This
    # array contains a list of arrays, one for each row, which in turn contains
    # a list of elements. An empty matrix has no rows.
    #
    #   [[ 1, 2, 3 ], [ 4, 5, 6 ]]  2-by-3 matrix
    #   [[ 1, 2, 3 ]]               1-by-3 matrix
    #   [[ 1 ], [ 2 ], [ 3 ]]       3-by-1 matrix
    #   [[ 1 ]]                     1-by-1 matrix
    #   []                          empty matrix

    else {

        my $data;

        # If there is a single argument, and that is not a reference,
        # assume new() has been called as, e.g., $class -> new(3).

        if (@_ == 1 && !ref($_[0])) {
            $data = [[ $_[0] ]];
        }

        # If there is a single argument, and that is a reference to an array,
        # and that array contains at least one element, and that element is
        # itself a reference to an array, then assume new() has been called
        # with the matrix as one argument, i.e., a reference to an array of
        # arrays, e.g., $class -> new([ [1, 2], [3, 4] ]) ...

        elsif (@_ == 1 && ref($_[0]) eq 'ARRAY'
               && @{$_[0]} > 0 && ref($_[0][0]) eq 'ARRAY')
        {
            $data = $_[0];
        }

        # ... otherwise assume that each argument to new() is a row. Note that
        # new() called with no arguments results in an empty matrix.

        else {
            $data = [ @_ ];
        }

        # Sanity checking.

        if (@$data) {
            my $nrow = @$data;
            my $ncol;

            for (my $i = 0 ; $i < $nrow ; ++$i) {
                my $row = $data -> [$i];

                # Verify that the row is a reference to an array.

                croak "row with index $i is not a reference to an array"
                  unless ref($row) eq 'ARRAY';

                # In the first round, get the number of elements, i.e., the
                # number of columns in the matrix. In the successive
                # rounds, verify that each row has the same number of
                # elements.

                if ($i == 0) {
                    $ncol = @$row;
                } else {
                    croak "each row must have the same number of elements"
                      unless @$row == $ncol;
                }
            }

            # Copy the data into $self only if the matrix is non-emtpy.

            @$self = map { [ @$_ ] } @$data if $ncol;
        }
    }

    bless $self, $class;
}

sub clone {
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $that = shift;
    my $self = [];

    for (@$that) {
        push(@{$self}, [@{$_}]);
    }
    bless $self, ref($that)||$that;
}

#
# Either class or object call, create a square matrix with the same
# dimensions as the passed-in list or array.
#
sub diagonal {
    my $that = shift;
    my $class = ref($that) || $that;
    my @diag = @_;
    my $self = [];

    # diagonal([2,3]) -> diagonal(2,3)
    @diag = @{$diag[0]} if (ref $diag[0] eq "ARRAY");

    my $len = scalar @diag;
    return undef if ($len == 0);

    for my $idx (0..$len-1) {
        my @r = (0) x $len;
        $r[$idx] = $diag[$idx];
        push(@{$self}, [@r]);
    }
    bless $self, $class;
}

#
# Either class or object call, create a square matrix with the same
# dimensions as the passed-in list or array.
#
sub tridiagonal {
    my $that = shift;
    my $class = ref($that) || $that;
    my(@up_d, @main_d, @low_d);
    my $self = [];

    #
    # Handle the different ways the tridiagonal vectors could
    # be passed in.
    #
    if (ref $_[0] eq "ARRAY") {
        @main_d = @{$_[0]};

        if (ref $_[1] eq "ARRAY") {
            @up_d = @{$_[1]};

            if (ref $_[2] eq "ARRAY") {
                @low_d = @{$_[2]};
            }
        }
    } else {
        @main_d = @_;
    }

    my $len = scalar @main_d;
    return undef if ($len == 0);

    #
    # Default the upper and lower diagonals if no vector
    # was passed in for them.
    #
    @up_d = (1) x ($len -1) if (scalar @up_d == 0);
    @low_d = @up_d if (scalar @low_d == 0);

    #
    # First row...
    #
    my @arow = (0) x $len;
    @arow[0..1] = ($main_d[0], $up_d[0]);
    push (@{$self}, [@arow]);

    #
    # Bulk of the matrix...
    #
    for my $idx (1 .. $#main_d - 1) {
        my @r = (0) x $len;
        @r[$idx-1 .. $idx+1] = ($low_d[$idx-1], $main_d[$idx], $up_d[$idx]);
        push (@{$self}, [@r]);
    }

    #
    # Last row.
    #
    my @zrow = (0) x $len;
    @zrow[$len-2..$len-1] = ($low_d[$#main_d -1], $main_d[$#main_d]);
    push (@{$self}, [@zrow]);

    bless $self, $class;
}

sub diagonal_vector {
    my $self = shift;
    my @diag;
    my $idx = 0;
    my($m, $n) = $self->size();

    die "Not a square matrix" if ($m != $n);

    foreach my $r (@{$self}) {
        push @diag, $r->[$idx++];
    }
    return \@diag;
}

sub tridiagonal_vector {
    my $self = shift;
    my(@main_d, @up_d, @low_d);
    my($m, $n) = $self->size();
    my $idx = 0;

    die "Not a square matrix" if ($m != $n);

    foreach my $r (@{$self}) {
        push @low_d, $r->[$idx - 1] if ($idx > 0);
        push @main_d, $r->[$idx++];
        push @up_d, $r->[$idx] if ($idx < $m);
    }
    return ([@main_d],[@up_d],[@low_d]);
}

sub size {
    my $self = shift;
    my $m = @{$self};
    my $n = @{$self->[0]};
    ($m, $n);
}

sub concat {
    my $self   = shift;
    my $other  = shift;
    my $result =  $self->clone();

    return undef if scalar(@{$self}) != scalar(@{$other});
    for my $i (0 .. $#{$self}) {
        push @{$result->[$i]}, @{$other->[$i]};
    }
    $result;
}

sub transpose {
    my ($matrix) = shift ;
    my @result = () ;
    my $lc = $#{$matrix->[0]};
    for my $col (0..$lc) {
        push @result, [map $_->[$col], @$matrix];
    }
    return( bless \@result, ref $matrix );
}

sub _vekpro {
    my($a, $b) = @_;
    my $result=0;

    for my $i (0 .. $#{$a}) {
        $result += $a->[$i] * $b->[$i];
    }
    $result;
}

sub multiply {
    my $self  = shift;
    my $class = ref($self);
    my $other = shift->transpose;
    my @result;

    return undef if $#{$self->[0]} != $#{$other->[0]};
    for my $row (@{$self}) {
        my $rescol = [];
        for my $col (@{$other}) {
            push(@{$rescol}, _vekpro($row,$col));
        }
        push(@result, $rescol);
    }
    $class->new(@result);
}

sub solve {
    my $self  = shift;
    my $class = ref($self);

    my $m    = $self->clone();
    my $mr   = $#{$m};
    my $mc   = $#{$m->[0]};
    my $f;
    my $try;

    return undef if $mc <= $mr;
  ROW: for(my $i = 0; $i <= $mr; $i++) {
        $try=$i;
        # make diagonal element nonzero if possible
        while (abs($m->[$i]->[$i]) < $eps) {
            last ROW if $try++ > $mr;
            my $row = splice(@{$m},$i,1);
            push(@{$m}, $row);
        }

        # normalize row
        $f = $m->[$i]->[$i];
        for (my $k = 0; $k <= $mc; $k++) {
            $m->[$i]->[$k] /= $f;
        }
        # subtract multiple of designated row from other rows
        for (my $j = 0; $j <= $mr; $j++) {
            next if $i == $j;
            $f = $m->[$j]->[$i];
            for (my $k = 0; $k <= $mc; $k++) {
                $m->[$j]->[$k] -= $m->[$i]->[$k] * $f;
            }
        }
    }
    # Answer is in augmented column
    transpose $class->new(@{$m->transpose}[$mr+1 .. $mc]);
}

sub pinvert {
    my $self  = shift;
    my $m    = $self->clone();

    $m->transpose->multiply($m)->invert->multiply($m->transpose);
}

sub print {
    my $self = shift;

    print @_ if scalar(@_);
    print $self->as_string;
}

sub as_string {
    my $self = shift;
    my $out = "";
    for my $row (@{$self}) {
        for my $col (@{$row}) {
            $out = $out . sprintf "%10.5f ", $col;
        }
        $out = $out . sprintf "\n";
    }
    $out;
}

sub new_identity {
    my $type = shift;
    my $class = ref($type) || $type;
    my $self = [];
    my $size = shift;

    for my $i (1..$size) {
        my $row = [];
        for my $j (1..$size) {
            push @$row, $i==$j ? 1 : 0;
        }
        push @$self, $row;
    }
    bless $self, $class;
}

sub eye {
    &new_identity(@_);
}

sub multiply_scalar {
    my $self = shift;
    my $factor = shift;
    my $result = $self->new();

    my $last = $#{$self->[0]};
    for my $i (0 .. $#{$self}) {
        for my $j (0 .. $last) {
            $result->[$i][$j] = $factor * $self->[$i][$j];
        }
    }
    $result;
}

sub negative {
    shift->multiply_scalar(-1);
}

sub subtract {
    my $self = shift;
    my $other = shift;

    # if $swap is present, $other operand isn't a Math::Matrix.  in
    # general that's undefined, but, if called as
    #   subtract($self,0,1)
    # we've been called as unary minus, which is defined.
    if ( @_  && $_[0] && ! ref $other && $other == 0 ) {
        $self->negative;
    } else {
        $self->add($other->negative);
    }
}

sub equal {
    my $A = shift;
    my $B = shift;
    my $ok = 1;

    my $last = $#{$A->[0]};
    for my $i (0 .. $#{$A}) {
        for my $j (0 .. $last) {
            abs($A->[$i][$j]-$B->[$i][$j])<$eps or $ok=0;
        }
    }
    $ok;
}

sub add {
    my $self = shift;
    my $other = shift;
    my $result = $self->new();

    return undef
      if $#{$self} != $#{$other};

    my $last= $#{$self->[0]};
    return undef
      if $last != $#{$other->[0]};
    for my $i (0 .. $#{$self}) {
        for my $j (0 .. $last) {
            $result->[$i][$j] = $self->[$i][$j] + $other->[$i][$j];
        }
    }
    $result;
}

sub slice {
    my $self = shift;
    my $class = ref($self);
    my $result = [];

    for my $i (0 .. $#$self) {
        push @$result, [ @{$self->[$i]}[@_] ];
    }

    bless $result, $class;
    $result -> clone();
}

sub determinant {
    my $self = shift;
    my $class = ref($self);
    my $imax = $#$self;
    my $jmax = $#{$self->[0]};

    return undef unless $imax == $jmax;     # input must be a square matrix

    if ($imax == 0) {
        return $self->[0][0];
    } else {
        my $result = 0;

        # Create a matrix with row 0 removed. We only need to do this once.
        my $matrix0 = $class -> new(@$self[1 .. $jmax]);

        foreach my $j (0 .. $jmax) {

            # Create a matrix with row 0 and column $j removed.
            my $matrix0j = $matrix0 -> slice(0 .. $j-1, $j+1 .. $jmax);

            my $term = $matrix0j -> determinant();
            $term *= $j % 2 ? -$self->[0][$j]
                            :  $self->[0][$j];

            $result += $term;
        }
        return $result;
    }
}

#
# For vectors only
#

sub dot_product {
    my $vector1 = shift;
    my $class = ref $vector1;

    my $vector2 = shift;

    # Allow the input to be an ordinary array, i.e., not an object. Ideally, we
    # should use the following test, but that requires the Scalar::Util module,
    # which might not be installed.
    #
    #   $vector2 = $class -> new($vector2)
    #     unless blessed($vector2) && $vector2 -> isa($class);

    $vector2 = $class -> new($vector2)
      if ref($vector2) eq 'ARRAY';

    $vector1 = $vector1->transpose()
      unless @$vector1 == 1;
    return undef
      unless @$vector1 == 1;

    $vector2 = $vector2->transpose()
      unless @{$vector2->[0]} == 1;
    return undef
      unless @{$vector2->[0]} == 1;

    return $vector1->multiply($vector2)->[0][0];
}

sub absolute {
    my $vector = shift;
    sqrt $vector->dot_product($vector);
}

sub normalize {
    my $vector = shift;
    my $length = $vector->absolute();
    return undef
      unless $length;
    $vector->multiply_scalar(1 / $length);
}

sub cross_product {
    my $vectors = shift;
    my $class = ref($vectors);

    my $dimensions = @{$vectors->[0]};
    return undef
      unless $dimensions == @$vectors + 1;

    my @axis;
    foreach my $column (0..$dimensions-1) {
        my $tmp = $vectors->slice(0..$column-1,
                                  $column+1..$dimensions-1);
        my $scalar = $tmp->determinant;
        $scalar *= ($column % 2) ? -1 : 1;
        push @axis, $scalar;
    }
    my $axis = $class->new(\@axis);
    $axis = $axis->multiply_scalar(($dimensions % 2) ? 1 : -1);
}

sub invert {
    my $M = shift;
    my ($m, $n) = $M->size;
    die "Matrix dimensions are $m X $n. -- Matrix not invertible.\n"
      if $m != $n;
    my $I = $M->new_identity($n);
    ($M->concat($I))->solve;
}

1;
