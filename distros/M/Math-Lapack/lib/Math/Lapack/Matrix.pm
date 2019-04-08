package Math::Lapack::Matrix;
$Math::Lapack::Matrix::VERSION = '0.002';
use strict;
use warnings;
use Scalar::Util 'blessed';
use Math::Lapack;
use parent 'Exporter';
use parent 'Math::Lapack::Expr';
our @EXPORT = qw(ones slice);



sub _bless {
    my $matrix = shift;
    return bless { _matrix => $matrix, type => 'matrix' } => __PACKAGE__;
}


sub zeros {
    my ($self, $r, $c) = @_;
    return _bless _zeros($r, $c);
}


sub ones {
	my($self, $r, $c) = @_;
	return _bless _ones($r, $c);
}


	
sub random {
	my($self, $r, $c) = @_;
	return _bless _random($r, $c);
}



sub identity {
	my($self, $r) = @_;
	return _bless _identity($r);
}



sub new {
	my ($self, $array) = @_;
	my $rows = scalar(@$array);
	my $cols = scalar(@{$array->[0]});
	my $i = 0;
	my $j;

	my $m = $self->zeros($rows, $cols);

	for my $row (@$array){
		$j = 0;
		die "Error!\n" unless $cols == scalar(@$row);
		for my $value (@$row){
			$m->set_element($i, $j, $value);
			$j++;
		}
		$i++;
	}
	return $m;
}


sub DESTROY {
	my $self = shift;
	_destroy($self->matrix_id);
}


sub get_element {
    my ($self, $i, $j) = @_;
    return _get_element($self->matrix_id, $i, $j);
}


sub shape {
    my $self = shift;
    return ($self->rows, $self->columns);
}


sub set_element {
    my ($self, $i, $j, $v) = @_;
    _set_element($self->matrix_id, $i, $j, $v);
}


sub rows {
	my $self = shift;
	return _rows($self->matrix_id);
}


sub columns {
	my $self = shift;
	return _cols($self->matrix_id);
}



sub get_max {
    my ($self) = @_;
    return _get_max($self->matrix_id);
}




sub get_min {
	my ($self) = @_;
	return _get_min($self->matrix_id);
}


sub mean {
	my ($self) = @_;
	return _mean($self->matrix_id);
}


sub std_deviation {
	my ($self) = @_;
	return _standard_deviation($self->matrix_id);
}


sub norm_mean {
	my ($self, %opts) = @_;
	return _bless _normalize_mean($self->matrix_id) unless( exists $opts{by} );
	_norm_mean_data($self->matrix_id, $opts{by}->matrix_id);
}


sub norm_std_deviation {
	my ($self, %opts) = @_;
	unless( exists $opts{by} ) {
			return _bless _normalize_std_deviation($self->matrix_id);
	}
	_norm_std_deviation_data($self->matrix_id, $opts{by}->matrix_id);
}



sub _add_matrices {
  my ($self, $other) = @_;
  return _bless __add_matrices($self->matrix_id, $other->matrix_id);
}

sub _add_elementwise {
    my ($self, $v) = @_;
    return _bless _matrix_sum($self->matrix_id, $v);
}

sub eval_add {
  my ($self, $other) = @_;

  if (ref($other) eq "Math::Lapack::Matrix" ) {
    return $self->_add_matrices($other);
  }
  else{
    return $self->_add_elementwise($other);
  }
}


sub _sub_matrices {
	my ($self, $other) = @_;
	return _bless __sub_matrices($self->matrix_id, $other->matrix_id);
}

sub _sub_elementwise {
  my ($self, $v, $swap) = @_;
  return _bless _matrix_sub($self->matrix_id, $v, $swap || 0);
}

sub eval_sub {
  my ($self, $other, $swap) = @_;

  if( blessed($other) && $other->isa("Math::Lapack::Expr")) {
    return $swap ? $other->_sub_matrices($self) : $self->_sub_matrices($other);
  }
  elsif (blessed($self)) {
    return $self->_sub_elementwise($other, $swap);
  }
  else {
    return $swap ? $other - $self : $self - $other;
  }
}


sub eval_dot {
	my ($self, $other, $is_self_T, $is_other_T) = @_;
	return _bless _dot($self->matrix_id, $other->matrix_id, $is_self_T || 0, $is_other_T || 0);
}



sub _mul_matrices {
  my ($self, $other) = @_;
  return _bless __mul_matrices($self->matrix_id, $other->matrix_id);
}

sub _mul_elementwise {
    my ($self, $v) = @_;
    return _bless _matrix_mul($self->matrix_id, $v);
}

sub eval_mul {
  my ($self, $other) = @_;
  if (ref($other) eq "Math::Lapack::Matrix") {
    return $self->_mul_matrices($other);
  }
  else {
    return $self->_mul_elementwise($other);
  }
}



sub _div_matrices {
	my ($self, $other) = @_;
	return _bless __div_matrices($self->matrix_id, $other->matrix_id);
}
sub _div_elementwise {
    my ($self, $v, $swap) = @_;
    die "Impossible divide by zeroi\n" if !$swap && $v == 0;
    return _bless _matrix_div($self->matrix_id, $v, $swap || 0);
}

sub eval_div {
  my ($self, $other, $swap) = @_;
  if( ref($other) eq "Math::Lapack::Matrix"){
    return $self->_div_matrices($other);
  }
  else{
    return $self->_div_elementwise($other, $swap);
  }
}


sub eval_transpose {
  my $self = shift;
	if ( blessed($self) && $self->isa("Math::Lapack::Expr")) {
    	return _bless _transpose($self->matrix_id);
  }
}



sub eval_inverse {
	my $self = shift;
	
	if ( blessed($self) && $self->isa("Math::Lapack::Expr")) {
    	return _bless _inverse($self->matrix_id);
  }
}


sub eval_exp {
    my $self = shift;
  
		if ( blessed($self) && $self->isa("Math::Lapack::Expr")) {
    	return _bless _exp($self->matrix_id);
  	}
}



sub eval_pow {
   	my ($self, $v) = @_;
		if( blessed($self) && $self->isa("Math::Lapack::Expr")) {
   		return _bless _pow($self->matrix_id, $v);
	}
}



sub eval_log {
  my $self = shift;

  if ( blessed($self) && $self->isa("Math::Lapack::Expr")) {
    return _bless _log($self->matrix_id);
  }
}


sub concatenate {
	my ($a, $b, $v) = @_;
	if(defined $v) {
			if ($v == 0 || $v == 1) {
				return _bless _concatenate($a->matrix_id, $b->matrix_id, $v);
			}
			die "Wrong index for concatenate matrices";
	}
	return _bless _concatenate($a->matrix_id, $b->matrix_id, 1);
}


sub append {
	my ($self, $m, $v) = @_;
	if(defined $v) {
			if ($v == 0 || $v == 1) {
				return _bless _concatenate($self->matrix_id, $m->matrix_id, $v);
			}
			die "Wrong index for append matrix";
	}
	return _bless _concatenate($self->matrix_id, $m->matrix_id, 1);
}






sub vector_to_list{
	my ($self) = @_;
	my ($m, $n) = $self->shape;
	my @list;
	if($m > 1 && $n == 1) {
		for (0..$m-1){
			push @list, $self->get_element($_,0);
		}
	}
	elsif( $m == 1 && $n > 1 ) {
		for (0..$n-1){
			push @list, $self->get_element(0,$_);
		}
	}
	else {print STDERR "Wrong dimensions to convert vector to list"; exit(1); }
	return @list;
}




sub eval_sum {
	my ($self, $v) = @_;
    return _bless _sum($self->matrix_id, -1) unless defined $v;
	return _bless _sum($self->matrix_id, $v);
}


sub slice {
    my ($self, %opts) = @_;
		my ($x0, $x1, $y0, $y1) = _values_to_slice(%opts);
		return _bless _slice($self->matrix_id, $x0, $x1, $y0, $y1);
    
}





sub read_csv{
	my ($file, %opts) = @_;
	my ($x0, $x1, $y0, $y1) = _values_to_slice(%opts);

	my ($rows, $cols) = rows_cols_from_file($file);
	
	$x0 = 0 if $x0 == -1;
	$y0 = 0 if $y0 == -1;
	$x1 = $rows - 1 if $x1 == -1;
	$y1 = $cols - 1 if $y1 == -1;


	open(my $data, '<', $file) or die "Could not open $file";

	my $m = Math::Lapack::Matrix->zeros($x1-$x0+1, $y1-$y0+1);

	my $i = 0;
	my $r = 0;
	while( <$data> ){
		if( $i >= $x0 && $i <= $x1){
				chomp;
				my @cols = split(/,/);
				my ($j, $c) = (0,0);
				for my $v (@cols){
					if($j >= $y0 && $j <= $y1){
						$m->set_element($r, $c, $v);
						$c++;
					}
					$j++;
				}
			$r++;
		}
		$i++;
	}
	close $data;
	return $m;

}

sub rows_cols_from_file {
		my ($file) = @_;
		open( my $data, '<', $file ) or die "Could not open $file";
		my $rows=0;my $cols = undef;
		while( <$data> ) {
				chomp;
				$cols = scalar( split(/,/) ) unless defined $cols;
				$rows++;
		}
		return ($rows, $cols);
}


sub save {
	my($self, $path) = @_;
	_matrix_save($self->matrix_id, $path);
  }


sub save_matlab {
  my ($self, $path) = @_;
  open my $output, ">", $path or die;
  print $output "[\n";
  my $rows = $self->rows;
  my $cols = $self->columns;
  for (my $l = 0; $l < $rows ; $l++) {
    for (my $c = 0; $c < $cols; $c++) {
      print $output $self->get_element($l, $c);
      print $output "," unless $c == $cols - 1;
    }
    print $output ";\n" unless $l == $rows - 1;
  }
  print $output "]\n";
  close $output;
}



sub read_matrix {
	my ($self, $path) = @_;
	return _bless _matrix_read($path);
}


sub _values_to_slice {
		my (%opts) = @_;
		
		my ($x0, $x1, $y0, $y1);

		if( defined $opts{row_range} ){
				if(ref($opts{row_range}) ne 'ARRAY' || scalar(@{$opts{row_range}}) != 2 ){
					die "row_range should be an array of two elements";
				}
				if(defined $opts{row}){
					die "You can't choose to slice with a row range and specific row";
				}
				$x0 = $opts{row_range}[0];
				$x1 = $opts{row_range}[1];
		}
		if( defined $opts{col_range} ){
				if(ref($opts{col_range}) ne 'ARRAY' || scalar(@{$opts{col_range}}) != 2 ){
					die "col_range should be an array of two elements";
				}
				if(defined $opts{col}){
					die "You can't choose to slice with a col range and specific column";
				}
				$y0 = $opts{col_range}[0];
				$y1 = $opts{col_range}[1];
		}
		$x0 = $x1 = $opts{row} if defined $opts{row};
		$y0 = $y1 = $opts{col} if defined $opts{col};
    $x0 = -1 unless defined $x0;
    $x1 = -1 unless defined $x1;
    $y0 = -1 unless defined $y0;
    $y1 = -1 unless defined $y1;

		return ($x0, $x1, $y0, $y1);
}


sub matrix_id {
  my $self = shift;
  if (exists $self->{_matrix}) {
    return $self->{_matrix};
  }
  die "Matrix id requested, but not available...";
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::Lapack::Matrix

=head1 VERSION

version 0.002

=for Pod::Coverage matrix_id eval_add eval_pow eval_div eval_dot eval_exp eval_sub eval_mul eval_sum eval_transpose rows_cols_from_file eval_inverse eval_log

=head1 CONSTRUCTORS

=head2 zeros

Allow the creation of a matrix with all values equal to zero.
Its arguments are the number of rows and the number of columns.

    my $m = Math::Lapack::Matrix->zeros(10, 20);

=head2 ones

Allow the creation of a matrix with all values equal to one.
Its arguments are the number of rows and the number of columns.

	my $m = Math::Lapack::Matrix->random(5,10);

=head2 random

Allow the creation of a matrix with all values set randomly between 0 and 1.
Its arguments are the number of rows and the number of columns.

	my $m = Math::Lapack::Matrix->random(15,15);

=head2 identity

Allow the creation of a identity matrix.
It argument is the size of the matrix.

	my $m = Math::Lapack::Matrix->identity(5);

=head2 new

Allow the creation of a new matrix.
It argument is a array of values to create the matrix.

	$m = Math::Lapack::Matrix->new( [ [1, 2], [3, 4] ] );

=head2 DESTROY

Allow free the memory allocated by a matrix.

	$m->DESTROY();

=head1 METHODS

=head2 get_element

Allow get specific element of matrix.
Its arguments are the position in row and the position in column.

	my $value = $m->get_element(1,2);

=head2 shape
Allow get the dimension of the matrix.

	($rows, $cols) = $m->shape();

=head2 set_element

Allow set element in matrix to specific position.
Its arguments are the position in row, the position in column and the value to set to that position.

	$m->set_element(1,0,10);

=head2 rows

Allow get the number of rows of a matrix.

	$rows = $m->rows();

=head2 columns

Allow get the number of columns of a matrix.

	$cols = $m->columns();

=head2 get_max

Allow get the max value of a matrix

	my $max = $a->max();

=head2 get_min

Allow get the min value of a matrix

	my $min = $a->min();

=head2 mean

Allow get the mean of values of a matrix

=head2 std_deviation

Allow get the standard deviation of the values of matrix

	my $std = $a->std_deviation();

=head2 norm_mean

Allow normalize every column of matrix by the mean.

	my $norm = $a->norm_mean();
This method will return a matrix with dimensions (a->columns, 2). This matrix have in the first row of every column the value max - min and in the second row of every column the mean that every column was normalized.

With this returned matrix you can normalize another matrix with same values of max-min and mean using the option by.

	my $new = $b->norm_mean( by => $norm ); 

=head2 norm_std_deviation

Allow normalize every column of matrix by the standard deviation.

	my $std = $a->norm_std_deviation();

This method will return a matrix with dimensions (a->columns, 2). This matrix have in the first row of every column the value mean and in the second row of every column the standard deviation that every column was normalized.

With this returned matrix you can normalize another matrix with same values of mean and standard deviation using the option "by".

	my $new = $b->norm_mean( by => $std ); 

=head1 OPERATIONS

=head2 addition

Allow make adiction of matrix by a scalar or by another matrix.
It argument is a scalar or matrix to add.

	$m = $m + $b
	$m = $m + 5;
	$m = $m->add($b);
	$m = $m->add(10);

=head2 subtraction

Allow make subtraction of matrix by a scalar or by another matrix.
It argument is a scalar or matrix to subtract.

	$m = $m - $b
	$m = $m - 5;
	$m = 5 - $m;
	$m = $m->sub($b);
	$m = $m->sub(10);

=head2 multiplication

Allow the multiplication of two matrices.
Its arguments are the 2 matrices to multiply.

    $A = Math::Lapack::Matrix->new( [ [1, 2], [3, 4] ] );
    $B = Math::Lapack::Matrix->new( [ [5, 6], [7, 8] ] );

    $C = $A->eval_dot($B);
    $D = $A x $B;   # alternative using operator overload

=head2 multiplication element-wise

Allow multiply a matrix by a scalar or a matrix by a matrix element-wise.
It argment is the scalar to multiply for every element of a matrix.

	$m = $m * 5;
	$m = 5 * $m;
	$m = $a * $b;
	$m = $m->mul(5);

=head2 division

Allow make the division of matrix by a scalar or by another matrix.
It argument is a scalar or matrix to divide.

	$m = $m / $b;
	$m = $m / 2;
	$m = 2 / $m;
	$m = $m->eval_div($b);
	$m = $m->eval_div(2);

=head2 transpose

Allow transpose a matrix.

	$m = $m->transpose();
	$m = transpose($m);
	$m = $m->T;

=head2 inverse

Allow make the operation of inverse to the elements of the matrix.

	$m = $m->inverse();
	$m = inverse($m);

=head2 exp

Allow make the exponential operation to every element of the matrix.

	$m = $m->exp();
	$m = exp($m);

=head2 pow

Allow apply the power operation to every element of the matrix.
It argument is the scalar to elevate every element of the matrix.

	$m = $m->pow(2);
	$m = pow($m,2);

=head2 log

Allow make the logarithm operation to every element of the matrix.

	$m = $m->log();
	$m = log($m);

=head2 concatenate

Allow the concatenation of two matrices, vertically.
Its arguments are the two matrices to concatenate

	index = 0 => concatenate in horizontally
  index = 1 => concatenate in vertically
	
	If it's not used index, by default the function will concatenate horizontally
	
	my $m = Math::Lapack::Matrix::concatenate($a, $b);
	my $m = Math::Lapack::Matrix::concatenate($a, $b, 0);
	my $m = Math::Lapack::Matrix::concatenate($a, $b, 1);

=head2 append

Allow append a matrix, vertically.
It argumet is the matrix to append.

	index = 0 => append in horizontally
  index = 1 => append in vertically
	
	If it's not used index, by default the function will append horizontally
	
	my $m = $a->append($b);
	my $m = $a->append($b,1);
	my $m = $a->append($b,0);

=head2 vector_to_list

Allow convert a vector with dimentions (m,1) or (1,m) to a list. where m is the number of elements and should be more than 1.

	my @vector = $a->vector_to_list();

=head2 sum

Allow sum elements of a matrix in horizontally or vertically.
It argument is a index that represent to sum in horizontally or vertically the elements of the matrix. If is not used index, the function sum will sum every element of the matrix.

    index = 0 => sum in horizontally
    index = 1 => sum in vertically

	$m = $m->sum(0);
	$m = sum($m,1);
	$m = sum($m);

=head2 slice

Allow slice over the elemenents of a matrix.
It argument is a hash of options. The options are:

	row_range => an array with two values of row min and row max to slice
	col_range => an array with two values of col min and col max to slice
	row => specific row
	col => specific column
    
	my $A = Math::Lapack::Matrix->new( 
					[    
            [1, 2, 3, 4, 5, 6],
            [7, 8, 9, 10, 11, 12],
            [13, 14, 15, 16, 17, 18]
          ]);

	#Get Specific row, row 0
	$A->slice( row_range => [0,0] );
	$A->slice( row => 0 );
	slice($A, row => 0);
	slice($A, row_range => [0,0]);
	
	#Get rows 1,2 and columns 2,3,4,5
	slice($A, row_range => [1,2], col_range => [2,5] );
	$A->slice( row_range => [1,2], col_range => [2,5] );

	#Get column 4
	$A->slice( col_range => [4,4] );
	$A->slice( col => 4 );
	slice($A, col => 4);
	slice($A, col_range => [4,4]);

=head1 I/O

=head2 read_csv

Allow read csv to a matrix.
Its arguments are the file and a hash of options. The options are:

	row_range => an array with two values of row min and row max to slice over the csv

	col_range => an array with two values of col min and col max to slice over the csv

	row => specific row
	col => specific column
    
	Math::Lapack::Matrix::read_csv($file, row_range => [1,22])

=head2 save

Allow save a matrix to disk.
It argument is the path to save the matrix.

	$m->save("path");

=head2 save_matlab

Allow save matrix to matlab format.
It argument is the path to save.

	$m->save_matlab("path.m");

=head2 read_matrix

Allow read a matrix to memory from disk.
It argument is the path to the file where the matrix as saved before.

	$m = Math::Lapack::matrix->read_matrix("path");

=head1 AUTHOR

Rui Meira

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2019 by Rui Meira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
