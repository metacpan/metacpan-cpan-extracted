package Math::Symbolic::Custom::Matrix;

use 5.006;
use strict;
use warnings;

=pod

=encoding utf8

=head1 NAME

Math::Symbolic::Custom::Matrix - Matrix routines for Math::Symbolic

=head1 VERSION

Version 0.2

=cut

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
    make_matrix
    make_symbolic_matrix
    identity_matrix
    add_matrix
    sub_matrix    
    multiply_matrix
    scalar_multiply_matrix
    scalar_divide_matrix
    order_of_matrix
    simplify_matrix
    transpose_matrix
    evaluate_matrix
    implement_matrix
    set_matrix
    cofactors_matrix
    adjugate_matrix
    invert_matrix
    is_square_matrix
    is_equals_matrix
    is_symmetric_matrix
    is_skew_symmetric_matrix
);

our $VERSION = '0.2';

use Math::Symbolic qw(:all);
use Math::Symbolic::MiscAlgebra qw/:all/;

use Carp;

=head1 DESCRIPTION

Provides some routines for manipulating matrices of Math::Symbolic expressions. A matrix here is just a 2D array of 
elements. Passing in matrices with elements which are not already Math::Symbolic objects will cause them to be 
converted to Math::Symbolic objects.

=head1 EXAMPLE

    use strict;
    use Math::Symbolic qw/:all/;
    use Math::Symbolic::MiscAlgebra qw/:all/;
    use Math::Symbolic::Custom::Matrix 0.2;
    use Math::Symbolic::Custom::Polynomial 0.11;
    use Math::Symbolic::Custom::CollectSimplify 0.2;
    Math::Symbolic::Custom::CollectSimplify->register();

    # Say we want the eigenvalues of some matrix with a parameter.
    # 1. A = | 4, 3-k |
    #        | 2, 3   |
    my @matrix = ([4,'3-k'],[2,3]);
    my $A = make_symbolic_matrix(\@matrix);

    # 2. get an identity matrix
    my $I = identity_matrix(2);

    # 3. multiply it with lambda
    my $lambda_I = scalar_multiply_matrix("lambda", $I);

    # 4. subtract it from matrix A
    my $B = sub_matrix($A, $lambda_I);

    # 5. form the characteristic polynomial, |A-lambda*I|
    my $c_poly = det(@{$B})->simplify();
    print "Characteristic polynomial is: $c_poly\n";

    # 6. analyze the polynomial to get roots
    my ($var, $coeffs, $disc, $roots) = $c_poly->test_polynomial('lambda');
    print "Expressions for the roots are:\n\t$roots->[0]\n\t$roots->[1]\n";

    # 7. Check for some values of parameter k
    foreach my $k (0..3) {
        print "For k = $k: lambda_1 = ", 
            $roots->[0]->value('k' => $k), "; lambda_2 = ", 
            $roots->[1]->value('k' => $k), "\n";
    }

=head1 EXPORTS

Everything below by default.

=head2 make_matrix

Creates a matrix of specified dimensions with every element set to the specified expression.

    use strict;
    use Math::Symbolic qw/:all/;
    use Math::Symbolic::Custom::Matrix;

    my $rows = 1;
    my $cols = 2;
    my $M = make_matrix('x', $rows, $cols);
    
=cut

sub make_matrix {
    my ($scalar, $r, $c) = @_;
    
    $scalar = Math::Symbolic::parse_from_string($scalar) if ref($scalar) !~ /^Math::Symbolic/;
    
    my @m;
    foreach my $i (0..$r-1) {
        foreach my $j (0..$c-1) {    
            $m[$i][$j] = $scalar;
        }
    }
    
    return \@m;
}

=head2 make_symbolic_matrix

Pass in an array reference to a 2D matrix. This routine will call Math::Symbolic's 
"parse_from_string()" function to convert any non-Math::Symbolic elements to Math::Symbolic
expressions. 

Returns an array reference to the resulting matrix. 

=cut

sub make_symbolic_matrix {
    my ($mat) = @_;

    my ($n_r, $n_c) = order_of_matrix($mat);

    my @sm;
    foreach my $i (0..$n_r-1) {
        foreach my $j (0..$n_c-1) {
            my $v = $mat->[$i][$j];
            my $ov = $v;
            if ( ref($ov) !~ /^Math::Symbolic/ ) {
                $ov = Math::Symbolic::parse_from_string($v);
            }
            $sm[$i][$j] = $ov;           
        }
    }

    return simplify_matrix(\@sm);
}

=head2 identity_matrix

Pass in the desired dimension of the (square) identity matrix. 

Returns an array reference to the resulting matrix (which will be composed of 
Math::Symbolic constants 1 and 0 where appropriate).

=cut

sub identity_matrix {
    my ($size) = @_;

    my @I;
    foreach my $i (0..$size-1) {
        foreach my $j (0..$size-1) {
            $I[$i][$j] = ($i == $j ? Math::Symbolic::Constant->new(1) : Math::Symbolic::Constant->new(0));
        }
    }

    return \@I;
}

=head2 add_matrix

Pass in two array references to the matrices to be added. 

Returns an array reference to the resulting matrix.

=cut

sub add_matrix {
    my ($m_a, $m_b) = @_;

    my @ao = order_of_matrix($m_a);
    my @bo = order_of_matrix($m_b);
    
    return undef unless ($ao[0] == $bo[0]) && ($ao[1] == $bo[1]);

    my @m_o;

    foreach my $i (0..$ao[0]-1) {
        foreach my $j (0..$ao[1]-1) {

            my $a_val = $m_a->[$i][$j];
            my $b_val = $m_b->[$i][$j];

            # if one of them (but not the other) is a Math::Symbolic object, then promote the not-Math::Symbolic value
            $a_val = Math::Symbolic::parse_from_string($a_val) if ref($a_val) !~ /^Math::Symbolic/;
            $b_val = Math::Symbolic::parse_from_string($b_val) if ref($b_val) !~ /^Math::Symbolic/;

            $m_o[$i][$j] = Math::Symbolic::Operator->new('+', $a_val, $b_val);
        }
    }

    return simplify_matrix(\@m_o);
}

=head2 sub_matrix

Pass in two array references to the matrices. Subtracts the second matrix from the first.

Returns an array reference to the resulting matrix.

=cut

sub sub_matrix {
    my ($m_a, $m_b) = @_;

    my @ao = order_of_matrix($m_a);
    my @bo = order_of_matrix($m_b);
    
    return undef unless ($ao[0] == $bo[0]) && ($ao[1] == $bo[1]);

    my @m_o;

    foreach my $i (0..$ao[0]-1) {
        foreach my $j (0..$ao[1]-1) {

            my $a_val = $m_a->[$i][$j];
            my $b_val = $m_b->[$i][$j];

            $a_val = Math::Symbolic::parse_from_string($a_val) if ref($a_val) !~ /^Math::Symbolic/;
            $b_val = Math::Symbolic::parse_from_string($b_val) if ref($b_val) !~ /^Math::Symbolic/;

            $m_o[$i][$j] = Math::Symbolic::Operator->new('-', $a_val, $b_val);
        }
    }

    return simplify_matrix(\@m_o);
}

=head2 multiply_matrix

Pass in array references to two matrices.

Returns an array reference to the matrix resulting from multiplying first matrix 
by the second.

=cut

sub multiply_matrix  {
    my ($m_a, $m_b) = @_;

    $m_a = make_symbolic_matrix($m_a);
    $m_b = make_symbolic_matrix($m_b);

    my ($m_a_rows, $m_a_cols) = order_of_matrix($m_a);
    my ($m_b_rows, $m_b_cols) = order_of_matrix($m_b);

    return undef unless $m_a_cols == $m_b_rows;
        
    my @m_o;
    foreach my $i (0..$m_a_rows-1) {
        foreach my $j (0..$m_b_cols-1) {
            my $m_o_ij;
            foreach my $k (0..$m_a_cols-1) {
                if ( defined $m_o_ij ) {
                    $m_o_ij = Math::Symbolic::Operator->new('+', $m_o_ij, Math::Symbolic::Operator->new('*', $m_a->[$i][$k], $m_b->[$k][$j]));
                }
                else {
                    $m_o_ij = Math::Symbolic::Operator->new('*', $m_a->[$i][$k], $m_b->[$k][$j]);
                }
            }
            $m_o[$i][$j] = $m_o_ij;
        }
    }
    
    return simplify_matrix(\@m_o);
}

=head2 scalar_multiply_matrix

This routine will multiply every element of a matrix by a single expression.

Pass in the expression and an array reference to the matrix.

Returns an array reference to the resulting matrix.

=cut

sub scalar_multiply_matrix {
    my ($scalar, $mat) = @_;
  
    $scalar = Math::Symbolic::parse_from_string($scalar) if ref($scalar) !~ /^Math::Symbolic/;
    $mat = make_symbolic_matrix($mat);

    my ($n_r, $n_c) = order_of_matrix($mat);

    my @sm;
    foreach my $i (0..$n_r-1) {
        foreach my $j (0..$n_c-1) {
            my $m_val = $mat->[$i][$j];
            $sm[$i][$j] = Math::Symbolic::Operator->new('*', $scalar, $m_val);
        }
    }

    return simplify_matrix(\@sm);
}

=head2 scalar_divide_matrix

This routine will produce an output matrix where every element is the input 
expression divided by every corresponding non-zero element of the input matrix. 
Elements which are zero are left untouched.

Pass in the expression and an array reference to the matrix.

Returns an array reference to the resulting matrix.

=cut

sub scalar_divide_matrix {
    my ($scalar, $mat) = @_;
  
    $scalar = Math::Symbolic::parse_from_string($scalar) if ref($scalar) !~ /^Math::Symbolic/;
    $mat = make_symbolic_matrix($mat);

    my ($n_r, $n_c) = order_of_matrix($mat);

    my @sm;
    foreach my $i (0..$n_r-1) {
        foreach my $j (0..$n_c-1) {
            my $m_val = $mat->[$i][$j];    
            my $m_val_v = $m_val->value();
            if ( defined($m_val_v) && ($m_val_v == 0) ) {
                $sm[$i][$j] = Math::Symbolic::Constant->new(0);
            }
            else {
                $sm[$i][$j] = Math::Symbolic::Operator->new('/', $scalar, $m_val);
            }
        }
    }

    return simplify_matrix(\@sm);
}

=head2 order_of_matrix

Pass in an array reference to a matrix.

This routine will return the number of rows and columns in the matrix. For example:-

    use strict;
    use Math::Symbolic qw/:all/;
    use Math::Symbolic::Custom::Matrix;

    my $A = make_symbolic_matrix([[1,2],[3,4],[5,6]]);
    my ($r, $c) = order_of_matrix($A);
    print "($r, $c)\n"; # (3, 2)

=cut

sub order_of_matrix {
    my ($mat) = @_;

    my $rows = scalar(@{$mat});
    my $cols;
    foreach my $row (@{$mat}) {
        my $c = scalar(@{$row});
        if ( defined $cols ) {
            if ( $c != $cols ) {                
                carp "order_of_matrix: Matrix is malformed!";
                return undef;
            }
        }
        else {
            $cols = $c;
        }
    }

    return ($rows, $cols);
}

=head2 simplify_matrix

This will call "simplify()" on every element of the matrix,
in an effort to tidy it up.

Pass in an array reference to the matrix.

Returns an array reference to the resulting matrix.

=cut

sub simplify_matrix {
    my ($mat) = @_;

    my ($n_r, $n_c) = order_of_matrix($mat);

    my @sm;
    foreach my $i (0..$n_r-1) {
        foreach my $j (0..$n_c-1) {

            my $m_val = $mat->[$i][$j];

            $m_val = Math::Symbolic::parse_from_string($m_val) if ref($m_val) !~ /^Math::Symbolic/;          

            if ( defined(my $m_val_s = $m_val->simplify()) ) {

                $sm[$i][$j] = $m_val_s;
            }            
            else {

                carp "simplify_matrix: Could not simplify!: $m_val";                
                $sm[$i][$j] = $m_val;
            }
        }
    }    
    
    return \@sm;
}

=head2 transpose_matrix

Pass in an array reference to a matrix.

Returns an array reference to the resulting transposed matrix.

=cut

sub transpose_matrix {
    my ($mat) = @_;

    return undef unless defined $mat;

    my ($n_r, $n_c) = order_of_matrix($mat);
    my @t;

    foreach my $i (0..$n_r-1) {
        foreach my $j (0..$n_c-1) {
            my $v = $mat->[$i][$j];
            return undef unless defined $v;
            $t[$j][$i] = $v;
        }
    }

    return \@t;
}

=head2 evaluate_matrix

This will call Math::Symbolic's "value()" method on each element
of the passed matrix.

Pass in an array reference to a matrix, and a hash ref which will be
passed in as the parameters to the "value()" method.

Returns an array reference to the resulting matrix.

=cut

sub evaluate_matrix {
    my ($mat, $vals) = @_;
    my %vals = %{$vals};

    my ($n_r, $n_c) = order_of_matrix($mat);

    my @vm;
    foreach my $i (0..$n_r-1) {
        foreach my $j (0..$n_c-1) {
            my $v = $mat->[$i][$j];
            if ( ref($v) =~ /^Math::Symbolic/ ) {
                $vm[$i][$j] = $v->value(%vals);
            }
        }
    }

    return \@vm;
}

=head2 implement_matrix

This will call Math::Symbolic's "implement()" method on each element
of the passed matrix.

Pass in an array reference to a matrix, and a hash ref which will be
passed in as the parameters to the "implement()" method.

Returns an array reference to the resulting matrix.

=cut

sub implement_matrix {
    my ($mat, $vals) = @_;
    my %vals = %{$vals};

    my ($n_r, $n_c) = order_of_matrix($mat);

    my @vm;
    foreach my $i (0..$n_r-1) {
        foreach my $j (0..$n_c-1) {
            my $v = $mat->[$i][$j];
            if ( ref($v) =~ /^Math::Symbolic/ ) {
                $vm[$i][$j] = $v->implement(%vals);
            }
        }
    }

    return \@vm;
}

=head2 set_matrix

This will call Math::Symbolic's "set_value()" method on each element
of the passed matrix.

Pass in an array reference to a matrix, and a hash ref which will be
passed in as the parameters to the "set_value()" method.

Returns an array reference to the resulting matrix.

=cut

sub set_matrix {
    my ($mat, $vals) = @_;
    my %vals = %{$vals};

    my ($n_r, $n_c) = order_of_matrix($mat);

    my @vm;
    foreach my $i (0..$n_r-1) {
        foreach my $j (0..$n_c-1) {
            my $v = $mat->[$i][$j];
            if ( ref($v) =~ /^Math::Symbolic/ ) {
                $vm[$i][$j] = $v->set_value(%vals);
            }
        }
    }

    return \@vm;
}

=head2 cofactors_matrix

Pass in an array reference to a matrix.

Returns an array reference to the resulting cofactors matrix.

=cut

sub cofactors_matrix {
    my ($mat) = @_;

    return undef unless is_square_matrix($mat);

    my ($n_r, $n_c) = order_of_matrix($mat);

    my @cofactors;
    foreach my $i (0..$n_r-1) {
        foreach my $j (0..$n_c-1) {
            
            # calculate minor matrix
            my @minor;
            my $x_i = 0;
            X_LOOP: foreach my $x (0..$n_r-1) {
                next X_LOOP if $x == $i;
                my $y_i = 0;
                Y_LOOP: foreach my $y (0..$n_c-1) {
                    next Y_LOOP if $y == $j;
                    $minor[$x_i][$y_i] = $mat->[$x][$y];
                    $y_i++;   
                }
                $x_i++;
            }

            # calculate determinant of that
            my $minor = det @minor;

            my $sign = (-1)**($i+$j);
            
            $cofactors[$i][$j] = Math::Symbolic::Operator->new('*', Math::Symbolic::Constant->new($sign), $minor);
        }
    }

    return \@cofactors;
}

=head2 adjugate_matrix

Pass in an array reference to a matrix.

Returns an array reference to the adjugate of the matrix.

=cut

sub adjugate_matrix {
    my ($mat) = @_;

    return undef unless is_square_matrix($mat);

    return transpose_matrix(cofactors_matrix($mat));
}

=head2 invert_matrix

Will attempt to invert the passed in matrix. Requires the
determinant to be non-zero; of course if the matrix has variables
then that won't necessarily be known until using the inverted
matrix later.

Pass in an array reference to a matrix.

Returns an array reference to the inverted matrix.

=cut
    
sub invert_matrix {
    my ($mat) = @_;

    return undef unless is_square_matrix($mat);

    # the determinant
    my $det = det @{$mat};
    my $s_det = $det->simplify();

    my $s_det_v = $s_det->value();
    return undef if defined($s_det_v) && ($s_det_v == 0);

    my $one = Math::Symbolic::Constant->new(1);
    my $det_reciprocal = Math::Symbolic::Operator->new('/', $one, $s_det);

    # the adjugate
    my $adj = adjugate_matrix($mat);
    return undef unless defined $adj;

    # complete the inversion
    my $inv = scalar_multiply_matrix($det_reciprocal, $adj);
   
    return simplify_matrix($inv);
}

=head2 is_square_matrix

Pass in an array ref to a matrix.

Returns 1 if the matrix is square, 0 otherwise.

=cut

sub is_square_matrix {
    my ($mat) = @_;

    my ($r, $c) = order_of_matrix($mat);
    return 1 if $r == $c;
    return 0;
}

=head2 is_equals_matrix

Pass in two array references for the matrices to compare.

Returns 1 if the matrices are equal (in terms of string expression),
0 otherwise.

=cut

sub is_equals_matrix {
    my ($m_a, $m_b) = @_;

    my @ao = order_of_matrix($m_a);
    my @bo = order_of_matrix($m_b);
    
    return 0 unless ($ao[0] == $bo[0]) && ($ao[1] == $bo[1]);    

    my $a_s = simplify_matrix($m_a);
    my $b_s = simplify_matrix($m_b);

    foreach my $i (0..$ao[0]-1) {
        foreach my $j (0..$ao[1]-1) {
            # FIXME: is_identical() (?)
            return 0 unless $m_a->[$i][$j]->to_string() eq $m_b->[$i][$j]->to_string();
        }
    }

    return 1;
}

=head2 is_symmetric_matrix

Pass in an array reference to a matrix.

Returns 1 if the matrix is symmetric, 0 otherwise.

=cut

sub is_symmetric_matrix {
    my ($mat) = @_;

    return 0 unless is_square_matrix($mat);
    return is_equals_matrix($mat, transpose_matrix($mat));
}

=head2 is_skew_symmetric_matrix

Pass in an array reference to a matrix.

Returns 1 if the matrix is skew-symmetric, 0 otherwise.

=cut

sub is_skew_symmetric_matrix {
    my ($mat) = @_;

    return 0 unless is_square_matrix($mat);
    return is_equals_matrix($mat, simplify_matrix(scalar_multiply_matrix(-1, transpose_matrix($mat)))   );
}

=head1 SEE ALSO

L<Math::Symbolic>

=head1 AUTHOR

Matt Johnson, C<< <mjohnson at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Steffen Mueller, author of Math::Symbolic

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Matt Johnson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


1; 
__END__


