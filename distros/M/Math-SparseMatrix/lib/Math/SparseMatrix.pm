package Math::SparseMatrix;

=head1 NAME

Math::SparseMatrix - Provides basic sparse matrix operations such as creation, reading from file, reading transpose from file and writing to file. 

=cut

use 5.006;
use strict;
use warnings;

require Exporter;
require Math::SparseVector;

use Math::SparseVector;


our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Math::SparseMatrix ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';

sub new {
    my $class = shift;
    my $rows = shift;
    my $cols = shift;

    if (!defined $rows || !defined $cols) {
        die "Math::SparseMatrix->new error.\n" .
            "USAGE: my \$spmatrix = Math::SparseMatrix->new(\$num_rows, \$num_cols);\n";
    }

    my $self = {
        _rows => $rows,
        _cols => $cols,
        _nnz => 0,
        _data => {}
    };

    bless $self, $class;
    return $self;
}

sub set {
    my $self = shift;
    my ($row, $col, $val) = @_;

    if (!defined $row || !defined $col || !defined $val) {
        die "Math::SparseMatrix->set error.\n" .
            "USAGE: \$spmatrix->set(\$row, \$col, \$val);\n";
    }

    if ($row < 1 || $row > $self->{_rows}) {
        die "Math::SparseMatrix->set error.\n" .
            "Row index out of bounds, must be between 1 and " .
            $self->{_rows} . " inclusive.\n";
    }
    
    if ($col < 1 || $col > $self->{_cols}) {
        die "Math::SparseMatrix->set error.\n" .
            "Column index out of bounds, must be between 1 and " .
            $self->{_cols} . " inclusive.\n";
    }

    if ($val == 0) {
        die "Math::SparseMatrix->set error.\n" .
            "Cannot store zero value in a sparse matrix.\n";
    }

    if (exists $self->{_data}->{$row}) {
        # update the number of non-zero elements in the matrix
        $self->{_nnz} -= scalar($self->{_data}->{$row}->keys);
        $self->{_data}{$row}->set($col,$val);
        $self->{_nnz} += scalar($self->{_data}->{$row}->keys);
    } else {
        $self->{_data}->{$row} = new Math::SparseVector();
        $self->{_data}->{$row}->set($col,$val);
        $self->{_nnz}++;
    }
}

sub get {
    my $self = shift;
    my ($row, $col) = @_;

    if (!defined $row || !defined $col) {
        die "Math::SparseMatrix->get error.\n" .
            "USAGE: \$val = \$spmatrix->get(\$row, \$col);\n";
    }

    if ($row < 1 || $row > $self->{_rows}) {
        die "Math::SparseMatrix->get error.\n" .
            "Row index out of bounds, must be between 1 and " .
            $self->{_rows} . " inclusive.\n";
    }
    
    if ($col < 1 || $col > $self->{_cols}) {
        die "Math::SparseMatrix->get error.\n" .
            "Column index out of bounds, must be between 1 and " .
            $self->{_cols} . " inclusive.\n";
    }

    if (exists $self->{_data}->{$row}) {
        return $self->{_data}->{$row}->get($col);
    } else {
        return 0;
    }
}

sub createFromFile {

    my $class = shift;
    my $infile = shift;

    if (!defined $infile) {
        die "Math::SparseMatrix->createFromFile error.\n" .
            "USAGE: my \$spmatrix = Math::SparseMatrix->createFromFile(\$input_file);\n";
    }

    if (!-f $infile) {
        die "Math::SparseMatrix->createFromFile error.\n" .
            "Cannot find file $infile.\n";
    }

    my $self = {
        _rows => 0,
        _cols => 0,
        _nnz => 0,
        _data => {}
    };

    open(INPUT, "< $infile") or
        die "Math::SparseMatrix->createFromFile error.\n" .
            "Failed to open sparse matrix input file $infile.\n";

    # read the number of rows, columns and the non-zero elements in the
    # file
    my $line = <INPUT>;
    chomp $line;
    my ($rows, $cols, $nnz) = split / +/, $line;
    $self->{_rows} = $rows;
    $self->{_cols} = $cols;
    # DO NOT SET THE NUMBER OF NON-ZEROS, THAT IS MANAGED BY THE set(...)
    # function, which is called below

    # create a Math::SparseMatrix object
    bless $self, $class;

    # also do error checks on file integrity
    my $lineNum = 0;
    my $nnzFound = 0;
    while ($line = <INPUT>) {
        chomp $line;
        $lineNum++;
        if ($lineNum > $rows) {
            die "Math::SparseMatrix->createFromFile error.\n". 
            "Number of rows in $infile is greater than that " .
            "mentioned in the file header ($rows).";
        }

        my @tokens = split / +/, $line;
        my $index;
        # process the <column, value> pairs in each line
        for ($index = 0; $index < @tokens; $index += 2) {
            # the column number of the current pair is the column 
            # number, and the current line number is the row number
            $self->set($lineNum, $tokens[$index], $tokens[$index + 1]);
            $nnzFound++;
        }
    }

    if ($nnzFound < $nnz) {
        die "Math::SparseMatrix->createFromFile error.\n". 
            "Number of non-zero elements found in $infile is less than that " .
            "mentioned in the file header -- $nnzFound < $nnz.\n";
    }

    if ($nnzFound > $nnz) {
        die "Math::SparseMatrix->createFromFile error.\n". 
            "Number of non-zero elements found in $infile is greater than that " .
            "mentioned in the file header -- $nnzFound > $nnz.\n";
    }

    # now the transposed matrix is loaded and ready to be returned
    return $self;
}

sub createTransposeFromFile {

    my $class = shift;
    my $infile = shift;

    if (!defined $infile) {
        die "Math::SparseMatrix->createTransposeFromFile error.\n" .
            "USAGE: \$my \$spmatrix = Math::SparseMatrix->createTransposeFromFile(\$input_file)\n";
    }

    if (!-f $infile) {
        die "Math::SparseMatrix->createTransposeFromFile error.\n" .
            "Cannot find file $infile.\n";
    }

    my $self = {
        _rows => 0,
        _cols => 0,
        _nnz => 0,
        _data => {}
    };

    open(INPUT, "< $infile") or
        die "Math::SparseMatrix->createTransposeFromFile error.\n" .
            "Failed to open sparse matrix input file $infile.\n";

    # read the number of rows, columns and the non-zero elements in the
    # file
    my $line = <INPUT>;
    chomp $line;
    my ($rows, $cols, $nnz) = split / +/, $line;
    # swap number of rows and columns
    $self->{_rows} = $cols;
    $self->{_cols} = $rows;
    # DO NOT SET THE NUMBER OF NON-ZEROS, THAT IS MANAGED BY THE set(...)
    # function, which is called below

    # create a Math::SparseMatrix object
    bless $self, $class;

    # also do error checks on file integrity
    my $lineNum = 0;
    my $nnzFound = 0;
    while ($line = <INPUT>) {
        chomp $line;
        $lineNum++;
        if ($lineNum > $rows) {
            die "Math::SparseMatrix->createTransposeFromFile error.\n". 
            "Number of columns in $infile is greater than that " .
            "mentioned in the file header ($rows).";
        }

        my @tokens = split / +/, $line;
        my $index;
        # process the <column, value> pairs in each line
        for ($index = 0; $index < @tokens; $index += 2) {
            # the column number of the current pair is the row
            # number in the transpose, the current line number is
            # the column number in the transpose
            $self->set($tokens[$index], $lineNum, $tokens[$index + 1]);
            $nnzFound++;
        }
    }

    if ($nnzFound < $nnz) {
        die "Math::SparseMatrix->createTransposeFromFile error.\n". 
            "Number of non-zero elements found in $infile is less than that " .
            "mentioned in the file header -- $nnzFound < $nnz.\n";
    }

    if ($nnzFound > $nnz) {
        die "Math::SparseMatrix->createTransposeFromFile error.\n". 
            "Number of non-zero elements found in $infile is greater than that " .
            "mentioned in the file header -- $nnzFound > $nnz.\n";
    }


    # now the transposed matrix is loaded and ready to be returned
    return $self;
}

sub writeToFile {

    my $self = shift;
    my $outfile = shift;

    if (!defined $outfile) {
        die "Math::SparseMatrix->writeToFile error.\n" .
            "USAGE: \$spmatrix->writeToFile (\$output_file);\n";
    }

    # write it to the output file
    open(OUTPUT, "> $outfile") or
        die "Math::SparseMatrix->writeToFile error.\n" .
            "Failed to create output file $outfile.\n";
    print OUTPUT $self->{_rows} . " " . $self->{_cols} . " " . 
        $self->{_nnz} . "\n";
    my $row;
    my $linecount = 1;
    foreach $row (sort {$a <=> $b} keys %{$self->{_data}}) {
        if ($row > $linecount) {
            # add empty lines for empty rows
            my $i = 0;
            my $limit = $row - $linecount;
            for ($i = 0; $i < $limit; $i++) {
                print OUTPUT "\n";
                $linecount++;
            }
        }
        my $vec = $self->{_data}->{$row};
        my $line = $vec->stringify();
        print OUTPUT $line . "\n";
        $linecount++;
    }
    close OUTPUT;
}

sub printDims {
    my $self = shift;
    print "Rows: " . $self->{_rows} . ". Cols: " . $self->{_cols} . ".\n";
}

1;
__END__

=head1 DESCRIPTION

Math::SparseMatrix provides simple sparse matrix functionality such as 
creation of sparse matrices, writing them out to a file, reading matrices from 
files and reading transpose of a matrix stored in a file.

=head1 SYNOPSIS

=over

=item 1. To begin with, Math::SparseMatrix should be included in your Perl program as follows:

    # include this module for use in your program
    use Math::SparseMatrix;
  
=item 2. To create an empty sparse matrix object with the required dimensions, use the following constructor:

    # create a new sparse matrix with 10 rows and 15 columns
    my $spmatrix = Math::SparseMatrix->new(10, 15);

=item 3. To update the values in the sparse matrix, use the "set" function as follows:

    # set the value at row 5, column 3 to 10
    $spmatrix->set(5, 3, 10);

=item 4. To retrieve a stored value, use the "get" function as follows:
  
    # get the value at row 6, column 5 if present, or zero
    $val = $spmatrix->get(6, 5);

=item 5. A sparse matrix can be written out to a file in the supported format (explained below) as follows:
   
    # write out the sparse matrix to the file "matrix.txt"
    $spmatrix->writeToFile("matrix.txt");

=item 6. A new sparse matrix object can be created from a file in the supported  format as follows:
   
    # create a matrix object by reading the file "matrix.txt"
    my $spmatrix = Math::SparseMatrix->createFromFile("matrix.txt");

=item 7. A new sparse matrix that is the transpose of the matrix stored in the given input file can be created as follows:
   
    # create the transpose of the matrix stored in "matrix.txt"
    my $spmatrix = Math::SparseMatrix->createTransposeFromFile("matrix.txt");
  
=item 8. Finally, to generate the transpose of a matrix stored in a file, read the transpose as in #7 above and write out the read transpose to a new file as in #5 above.
 
    # create the transpose of the matrix stored in "matrix.txt"
    my $spmatrix = Math::SparseMatrix->createTransposeFromFile("matrix.txt");
    
    # write out the created transpose to another file "transpose.txt"
    $spmatrix->writeToFile("transpose.txt");

=back

=head1 SPARSE DATA FORMAT

The sparse matrix file format that Math::SparseMatrix expects is described
below with an example.

The first line (or the header line) of the file should contain 3 number 
separated by a single space.
The first number is the number of rows in the sparse matrix, the second
number is the number of columns and the third number is the number of non-zero
elements present in the stored matrix.

Each subsequent line represents one row of the sparse matrix, therefore there
should be as many number of lines after the header line as the number of rows
mentioned in the header line. In every line representing a row, there should
be as many pairs of numbers as the number of non-zero elements in that row.
The first number in the pair represents the column number of the non-zero
element (column numbers start with 1). The row number is implicitly provided
by the line
number in the file. The second number in the pair is the actual non-zero
matrix element. Numbers in a pair and multiple pairs should all be separated
by single spaces. If a row does not contain any non-zero element, then an
empty line should be present in the file.

NOTE: There should be no empty lines except those representing empty rows,
neither should there be any comment lines. Commenting is not supported.

Consider the sparse matrix of 5 rows and 4 columns below:

  10    0    0    0
   0    0    6    8
   0    0    0    0
   0   21    0    0
   7    0    0    9

The sparse file representation for the same is:

  5 4 6
  1 10
  3 6 4 8

  2 21
  1 7 4 9

Notice the empty line in between for the third row.

=head1 SEE ALSO

Math::SparseVector

=head1 AUTHORS

Ted Pedersen, University of Minnesota, Duluth.
tpederse at d.umn.edu

Mahesh Joshi, Carnegie-Mellon University
maheshj @ cmu.edu

=head1 COPYRIGHT

Copyright (c) 2006-2008, Ted Pedersen and Mahesh Joshi

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to

 The Free Software Foundation, Inc.,
 59 Temple Place - Suite 330,
 Boston, MA  02111-1307, USA.

=cut

