package Matrix::Simple;

use strict;
use warnings;
use vars qw{@EXPORT $VERSION @ISA};
use Exporter;

@EXPORT  = qw{stand det tran adj num_mult inv sub add mult show};
$VERSION = qq{1.04};
@ISA     = qw{Exporter};

#=====================================================================

#some subroutines as follows :

#=====================================================================

#Standardize data into two-dimensional array form
sub stand{
    my @matrix;
    if(@_ == 1){
        my ($file) = @_;
        open my $fh_data, '<', $file or die "can't open $file:$!";
        while(<$fh_data>){
            chomp;
            next unless $_;
            push @matrix, [ split ];
        }
        close $fh_data;
    }
    elsif(@_ >= 3){
        if(@_ > 3){
            print "The parameters of entered are too many!\n";
            print "The first three parameters are used by default!\n";
        }
        my ($data, $row, $col) = @_;
        if(@$data != $row*$col){
            print "Error: the number of data isn't equal to the number of rows multiplied by the number of columns!\n";
            return 'error';
        }
        for(my $i = 0; $i < @$data; $i += $col){
            push @matrix, [ @{$data}[$i .. $i+$col-1] ];
        }
    }
    else{
        print "The parameters of entered is incorrect!\n";
        return 'error';
    }
    return \@matrix;
}

#Calculate the determinant of a matrix by Laplace expansion
sub det{
    my $matrix = shift;
    if(@$matrix != @{$matrix->[0]}){
        warn "Can't calculate the determinant of the matrix: matrix isn't a square matrix!\n";
        return 'error';
    }
    our $value = shift || 0;
    foreach my $k (0 .. $#{$matrix->[0]}){
        my $element = ((-1)**($k))*$matrix->[0][$k];
        my $low_order;
        foreach my $i (1 .. $#$matrix){
            foreach my $j (0 .. $#{$matrix->[$i]}){
                next if $k == $j;
                push @{$low_order->[$i-1]}, $matrix->[$i][$j];
            }
        }
        $low_order->[0][$_] *= $element foreach 0 .. $#{$low_order->[0]};
        if(@$low_order == 1){
            $value += defined $low_order->[0][0] ? $low_order->[0][0] : $matrix->[0][0];
        }
        else{
            &det($low_order, $value);
        }
    }
    return $value;
}

#Get the transposed matrix of the matrix
sub tran{
    my $original = shift;
    my @transpose;
    foreach my $i (0 .. $#$original){
        foreach my $j (0 .. $#{$original->[$i]}){
            $transpose[$j][$i] = $original->[$i][$j];
        }
    }
    return \@transpose;
}

#Get the adjugate matrix of the matrix
sub adj{
    my $matrix = shift;
    if(@$matrix != @{$matrix->[0]}){
        warn "Can't get the adjugate matrix of the matrix: matrix isn't a square matrix!\n";
        return 'error';
    }
    if(@$matrix == 1){
        warn "The matrix is a first-order matrix!\n";
        return 'error';
    }
    my @adjugate_tmp;
    foreach my $i (0 .. $#$matrix){
        foreach my $j (0 .. $#{$matrix->[$i]}){
            my @tmp;
            foreach my $p (0 .. $#$matrix){
                foreach my $q (0 .. $#{$matrix->[$i]}){
                    push @tmp, $matrix->[$p][$q] if $p != $i and $q != $j;
                }
            }
            my @low_order;
            for(my $n = 0; $n < @tmp; $n += $#{$matrix->[0]}){
                push @low_order, [ @tmp[$n .. $n+$#{$matrix->[0]}-1] ];
            }
            $adjugate_tmp[$i][$j] = ((-1)**($i+$j))*&det(\@low_order);
        }
    }
    my $adjugate = &tran(\@adjugate_tmp);
    return $adjugate;
}

#Multiplication of number and matrix
sub num_mult{
    my ($num, $matrix) = @_;
    my @result;
    foreach my $i (0 .. $#$matrix){
        foreach my $j (0 .. $#{$matrix->[$i]}){
            $result[$i][$j] = $num*$matrix->[$i][$j];
        }
    }
    return \@result;
}

#Get the inverse matrix of the matrix
sub inv{
    my ($matrix, $round) = @_;
    $round = 2 unless defined $round;
    my $det_value = &det($matrix);
    if($det_value == 0){
        warn "Can't get the inverse matrix of the matrix: the determinant of the matrix is 0!\n";
        return 'error';
    }
    if($det_value eq 'error'){
        return 'error';
    }
    if(@$matrix == 1){
        my $digit = sprintf "%.${round}f", 1/$det_value;
        my @inverse = ([$digit]);
        return \@inverse;
    }
    my $adjugate = &adj($matrix);
    my $inverse = &num_mult(1/$det_value, $adjugate);
    foreach my $i (0 .. $#$inverse){
        foreach my $j (0 .. $#{$inverse->[$i]}){
            $inverse->[$i][$j] = sprintf "%.${round}f", $inverse->[$i][$j];
        }
    }
    return $inverse;
}

#Subtraction of matrix and matrix
sub sub{
    my ($matrix_1, $matrix_2) = @_;
    if(@$matrix_1 != @$matrix_2 or @{$matrix_1->[0]} != @{$matrix_2->[0]}){
        warn "These two matrices can't be subtracted!\n";
        return 'error';
    }
    my @result;
    foreach my $i (0 .. $#$matrix_1){
        foreach my $j (0 .. $#{$matrix_1->[$i]}){
            $result[$i][$j] = $matrix_1->[$i][$j] - $matrix_2->[$i][$j];
        }
    }
    return \@result;
}

#Addition of matrix and matrix
sub add{
    my ($matrix_1, $matrix_2) = @_;
    if(@$matrix_1 != @$matrix_2 or @{$matrix_1->[0]} != @{$matrix_2->[0]}){
        warn "These two matrices can't be added!\n";
        return 'error';
    }
    my @result;
    foreach my $i (0 .. $#$matrix_1){
        foreach my $j (0 .. $#{$matrix_1->[$i]}){
            $result[$i][$j] = $matrix_1->[$i][$j] + $matrix_2->[$i][$j];
        }
    }
    return \@result;
}

#Multiplication of matrix and matrix
sub mult{
    my ($matrix_1, $matrix_2) = @_;
    if(@{$matrix_1->[0]} != @$matrix_2){
        warn "These two matrices can't be multiplied!\n";
        return 'error';
    }
    my @result;
    foreach my $i (0 .. $#$matrix_1){
        foreach my $j (0 .. $#{$matrix_2->[0]}){
            foreach my $k (0 .. $#$matrix_2){
                $result[$i][$j] += $matrix_1->[$i][$k]*$matrix_2->[$k][$j];
            }
        }
    }
    return \@result;
}

#Show matrix to specified place
sub show{
    my ($matrix, $place) = @_;
    if(defined $place){
        open my $fh_matrix, '>', $place or die "can't generate $place:$!";
        foreach my $i (0 .. $#$matrix){
            foreach my $j (0 .. $#{$matrix->[$i]}){
                print $fh_matrix $matrix->[$i][$j], $j != $#{$matrix->[$i]} ? "\t" : "\n";
            }
        }
        close $fh_matrix;
    }
    else{
        foreach my $i (0 .. $#$matrix){
            foreach my $j (0 .. $#{$matrix->[$i]}){
                print $matrix->[$i][$j], $j != $#{$matrix->[$i]} ? "\t" : "\n";
            }
        }
    }
}

1;

__END__

=head1 NAME

Matrix::Simple - Some simple matrix operations

=head1 SYNOPSIS

    use Matrix::Simple;

    my $matrix = stand($in_file_name);
    my $matrix = stand(\@data, $row, $col);

    my $value = det($matrix);
    my $value = det(\@matrix);

    my $tran_matrix = tran($matrix);
    my $tran_matrix = tran(\@matrix);

    my $adj_matrix = adj($matrix);
    my $adj_matrix = adj(\@matrix);

    my $inv_matrix = inv($matrix, $round);
    my $inv_matrix = inv(\@matrix, $round);

    my $new_matrix = num_mult($num, $matrix);
    my $new_matrix = num_mult($num, \@matrix);

    my $new_matrix = sub($matrix_1, $matrix_2);
    my $new_matrix = sub(\@matrix_1, \@matrix_2);
    
    my $new_matrix = add($matrix_1, $matrix_2);
    my $new_matrix = add(\@matrix_1, \@matrix_2);

    my $new_matrix = mult($matrix_1, $matrix_2);
    my $new_matrix = mult(\@matrix_1, \@matrix_2);

    show($matrix);
    show(\@matrix);
    show($matrix, $out_file_name);
    show(\@matrix, $out_file_name);

=head1 VERSION

1.04

=head1 DESCRIPTION

This module provides 10 subroutines for simple matrix operations.
With this module, you can:

=over 10

=item 1.

generate standard two-dimensional matrix form

=item 2.

calculate the determinant of the matrix

=item 3.

get the transposed matrix of the matrix

=item 4.

get the adjoint matrix of the matrix

=item 5.

get the inverse matrix of the matrix

=item 6.

multiplication between number and matrix

=item 7.

subtraction between matrix and matrix

=item 8.

addition between matrix and matrix

=item 9.

multiplication between matrix and matrix

=item 10.

display matrix to designated terminal

=back

=head1 FUNCTION

The specific function and usage of each subroutine as follows:

=over 10

=item I<stand>

Standardize data into two-dimensional array form (two method).

    1. read data from text file (each line is separated by white space)
    my $matrix = stand($in_file_name);
    
    2. normalize a one-dimensional array into a two-dimensional array
    my $matrix = stand(\@data, $row, $col);

    notice: $row and $col are the number of rows and columns, respectively

=item I<det>

Calculate the determinant of a matrix by Laplace expansion.

    my $value = det($matrix);  #two-dimensional array reference
    my $value = det(\@matrix); #two-dimensional array

=item I<tran>

Get the transposed matrix of the matrix.

    my $tran_matrix = tran($matrix);  #two-dimensional array reference
    my $tran_matrix = tran(\@matrix); #two-dimensional array

=item I<adj>

Get the adjugate matrix of the matrix.

    my $adj_matrix = adj($matrix);  #two-dimensional array reference
    my $adj_matrix = adj(\@matrix); #two-dimensional array

=item I<inv>

Get the inverse matrix of the matrix.

    my $inv_matrix = inv($matrix, $round);  #two-dimensional array reference
    my $inv_matrix = inv(\@matrix, $round); #two-dimensional array
    
    notice: $round is the number of decimal places to keep(default : 2)

=item I<num_mult>

Multiplication of number and matrix.

    my $new_matrix = num_mult($num, $matrix);  #two-dimensional array reference
    my $new_matrix = num_mult($num, \@matrix); #two-dimensional array

=item I<sub>

Subtraction of matrix and matrix.

    my $new_matrix = sub($matrix_1, $matrix_2);   #two-dimensional array reference
    my $new_matrix = sub(\@matrix_1, \@matrix_2); #two-dimensional array

=item I<add>

Addition of matrix and matrix.

    my $new_matrix = add($matrix_1, $matrix_2);   #two-dimensional array reference
    my $new_matrix = add(\@matrix_1, \@matrix_2); #two-dimensional array

=item I<mult>

Multiplication of matrix and matrix.

    my $new_matrix = mult($matrix_1, $matrix_2);   #two-dimensional array reference
    my $new_matrix = mult(\@matrix_1, \@matrix_2); #two-dimensional array

=item I<show>

Show matrix to specified place (two place).

    1. show to STDOUT
    show($matrix);  #two-dimensional array reference
    show(\@matrix); #two-dimensional array

    2. show to file
    show($matrix, $out_file_name);  #two-dimensional array reference
    show(\@matrix, $out_file_name); #two-dimensional array

=back

=head1 AUTHOR

Xiangjian Gou

=head1 EMAIL

862137261@qq.com

=head1 DATE

11/30/2018

=cut
