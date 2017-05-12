package Math::SparseMatrix::Operations;

use v5.10;

use parent qw( Exporter );
require Exporter;
use Math::SparseMatrix;

@ISA = ("Exporter");
@EXPORT = qw(&op_fill_matrix 
			&op_print_matrix
			&op_transpose
			&op_multiply
			&op_identity
			&op_subtraction
			&op_addition
			&op_dot_product
			&op_get_col
			&op_get_row
);

use warnings;
use strict;

=head1 NAME

Math::SparseMatrix::Operations - Mathematical operations with matrices

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.06';


# returns the position and the content of each cell.
sub op_print_matrix {
    my $matrix  = shift;
    my $rs = $matrix->{_rows};
    my $cs = $matrix->{_cols};

	for (my $i = 1; $i <= $rs; $i++) {
		for (my $j = 1; $j <= $cs; $j++) {
			print "[$i,$j]" . $matrix->get($i, $j) . "\t";
		}
		print "\n";
	}
}

# each matrix cell recieves a '1' as a value.
sub op_fill_matrix {
    my $matrix  = shift;
    my $rs = $matrix->{_rows};
    my $cs = $matrix->{_cols};

	for (my $i = 1; $i <= $rs; $i++) {
		for (my $j = 1; $j <= $cs; $j++) {
			$matrix->set($i, $j, 1);
		}
	}
}


# standard matrix transposition.
sub op_transpose {
	my $matrix  = shift;
	my $rows = $matrix->{_rows};
	my $cols = $matrix->{_cols};

	my $inverse = Math::SparseMatrix->new($cols, $rows);
		
	for (my $r = 1; $r <= $rows; $r++) {
		for (my $c = 1; $c <= $cols; $c++) {
			my $value = $matrix->get($r, $c);
			$inverse->set($c, $r, $value);
		}
	}
	return $inverse;
}

# standard matrix multiplication
sub op_multiply {
	my $matrix_a  = shift;
	my $matrix_b  = shift;

	my $a_rows = $matrix_a->{_rows};
	my $a_cols = $matrix_a->{_cols};

	my $b_rows = $matrix_b->{_rows};
	my $b_cols = $matrix_b->{_cols};

	my $result = Math::SparseMatrix->new($a_rows, $b_cols);

	if ($matrix_a->{_cols} != $matrix_b->{_rows}) {
		die "To use ordinary matrix multiplication the number of columns on the first matrix must mat the number of rows on the second";
	}

	for (my $result_row = 1; $result_row <= $a_rows; $result_row++) {
		for(my $result_col = 1; $result_col <= $b_cols; $result_col++) {
			my $value = 0;
			for (my $i = 1; $i <= $a_cols; $i++) {
				$value += ($matrix_a->get($result_row, $i)) * ($matrix_b->get($i, $result_col));
			}
			$result->set($result_row, $result_col, $value);
		}
	}
	return $result;
}

# standard matrix identity
sub op_identity {
	my $size = shift;

	if ($size < 1) {
		die "Identity matrix must be at least of size 1.";
	}
	
	my $result = Math::SparseMatrix->new ($size, $size);

	for (my $i = 1; $i <= $size; $i++) {
		$result->set($i, $i, 1);
	}
	return $result;
}

# standard matrix identity
sub op_subtraction {
	my $matrix_a = shift;
	my $matrix_b = shift;

    my $a_rows = $matrix_a->{_rows};
    my $a_cols = $matrix_a->{_cols};

	my $b_rows = $matrix_b->{_rows};
	my $b_cols = $matrix_b->{_cols};

	if ($a_rows != $b_rows) {
		die "To subtract the matrixes they must have the same number of rows and columns.";
	}

	if ($a_cols != $b_cols) {
		die "To subtract the matrixes they must have the same number of rows and columns.  Matrix a has ";
	}

	my $result = Math::SparseMatrix->new($a_rows, $a_cols);

	for (my $result_row = 1; $result_row <= $a_rows; $result_row++) {
		for (my $result_col = 1; $result_col <= $a_cols; $result_col++) {
			my $value = ( $matrix_a->get($result_row, $result_col) ) - ( $matrix_b->get($result_row, $result_col));
			
			if ($value == 0) {
				$value += 2;
			}			
			$result->set($result_row, $result_col, $value);
		}
	}
	return $result;
}

# standard matrix addition.
sub op_addition {
	#weight matrix.
    my $matrix_a = shift;
	#identity matrix.
    my $matrix_b = shift;

	my $a_rows = $matrix_a->{_rows};
	my $a_cols = $matrix_a->{_cols};

	my $b_rows = $matrix_b->{_rows};
	my $b_cols = $matrix_b->{_cols};
	
	if ($a_rows != $b_rows) {
		die "To add the matrixes they must have the same number of rows and columns.";
	}

	if ($a_cols != $b_cols) {
		 die "To add the matrixes they must have the same number of rows and columns.";
	}

	my $result = Math::SparseMatrix->new($a_rows, $a_cols);

	for (my $result_row = 1; $result_row <= $a_rows; $result_row++) {
		for (my $result_col = 1; $result_col <= $a_cols; $result_col++) {
			my $value = $matrix_b->get($result_row, $result_col);			
			$result->set($result_row, $result_col, $matrix_a->get($result_row, $result_col) + $value  )
		}
	}
	return $result;
}

# standard matrix dot product.
sub op_dot_product {
	my $matrix_a = shift;
	my $matrix_b = shift;
	
	my $a_rows = $matrix_a->{_rows};
	my $a_cols = $matrix_a->{_cols};
	
	my $b_rows = $matrix_b->{_rows};
	my $b_cols = $matrix_b->{_cols};

	my @array_a = &packed_array($matrix_a);
	my @array_b = &packed_array($matrix_b);

	for (my $n = 0; $n <= $#array_b; $n++) {
		if ($array_b[$n] == 2) {
			$array_b[$n] = 0;
		}
	}
	
	if ($#array_a != $#array_b) {
		die "To take the dot product, both matrixes must be of the same length.";
	}

	my $result = 0;
	my $length = $#array_a + 1;

	for (my $i = 0; $i < $length; $i++) {
		$result += $array_a[$i] * $array_b[$i];
	}
	return $result;
}

# returns a specific column from the matrix.
sub op_get_col {
	my $self = shift;
	my $col  = shift;

	my $matrix = $self->matrix();
	
	my $matrix_rows = $self->matrix_rows();

	if ($col > $matrix_rows) {
		die "Can't get column";
	}

	my $new_matrix = Math::SparseMatrix->new($matrix_rows, 1);

	for (my $row = 1; $row <= $matrix_rows; $row++) {
		my $value = $matrix->get($row, $col);
		$new_matrix->set($row, 1, $value);
	}
	return $new_matrix;
}

#returns a specific cow from the matrix.
sub op_get_row {
	my $self  = shift;
	my $row   = shift;

	my $matrix = $self->matrix();

	my $matrix_cols = $self->matrix_cols();

	if ($row > $matrix_cols) {
		die "Can't get row";
	}

	my $new_matrix = Math::SparseMatrix->new(1, $matrix_cols);

	for (my $col = 1; $col <= $matrix_cols; $col++) {
		my $value = $matrix->get($row, $col);
		$new_matrix->set(1, $col, $value);
	}

	return $new_matrix;
}

1;
=head1 SYNOPSIS

This module introduces new utilities and mathematical functions for matrices from the module Math::SparseMatrix. This is not a class module, it contains only
the subroutines for the operations. All the subroutines described below will only function with Math::SparseMatrix objects.

Please consider the subroutines names before using the module, the module usage will bring to your namespace all the subroutines described below.

=head1 SUBROUTINES

=head2 Print

This subroutines prints the value of each cell.

	# Input: $matrix_a.
	# Output: matrix content.
	&op_print_matrix($matrix_a);

=cut

=head2 Fill Matrix

This subroutines puts a number 1 inside each matrix cell.

	# Input: $matrix_a.
	# Output: none.
	&op_fill_matrix($matrix_a);

=cut

=head2 Get Column

Returns a new Math::SparseMatrix object with the selected column. (Not tested yet!)

	# Input: $matrix_a, $column_number.
	# Output: $matrix_b.
	my $matrix_b = &get_col($matrix_a, $column_number);

=cut

=head2 Get Row

Returns a new Math::SparseMatrix object with the selected row. (Not Tested Yest!)

	# Input: $matrix_a, $row_number.
	# Output: $matrix_b.
	my $matrix_b = &get_col($matrix_a, $column_number);

=cut

=head2 Addition

Basic matrix addition, returns a new Math::SparseMatrix object.

	# Input: $matrix_a, $matrix_b.
	# Output: $matrix_c.
	my $matrix_c = &op_addition($matrix_a, $matrix_b);

=cut

=head2 Subtraction

Basic matrix subtraction, returns a new Math::SparseMatrix object.

	# Input: $matrix_a, $matrix_b.
	# Output: $matrix_c.
	my $matrix_c = &op_subtraction($matrix_a, $matrix_b);

=cut

=head2 Multiplication

Basic matrix multiplication, returns a new Math::SparseMatrix object.

	# Input: $matrix_a, $matrix_b.
	# Output: $matrix_c.
	my $matrix_c = &op_multiply($matrix_a, $matrix_b);

=cut

=head2 Identity

Returns the identity matrix for the given input matrix. Returns a new Math::SparseMatrix object.

	# Input: $size.
	# Output: $matrix_a.
	my $matrix_a = &op_identity($size);

=cut

=head2 Transposition

Returns the transposed matrix for the given input matrix. Returns a new Math::SparseMatrix object.

	# Input: $matrix_a.
	# Output: $matrix_b.
	my $matrix_b = &op_transpose($matrix_a);

=cut

=head2 Dot Product

Returns the dot product for the given input matrix.

	# Input: $matrix_a.
	# Output: $dot_product.
	my $dot_product = &op_dot_product($matrix_a);

=cut



=head1 AUTHOR

Felipe da V. Leprevost, C<< <leprevost at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-sparsematrix-operations at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-SparseMatrix-Operations>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::SparseMatrix::Operations


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-SparseMatrix-Operations>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-SparseMatrix-Operations>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-SparseMatrix-Operations>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-SparseMatrix-Operations/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Felipe da V. Leprevost.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

# End of Math::SparseMatrix::Operations
