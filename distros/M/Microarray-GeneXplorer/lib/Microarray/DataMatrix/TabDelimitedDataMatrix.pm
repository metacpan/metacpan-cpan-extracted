package Microarray::DataMatrix::TabDelimitedDataMatrix;

# License information (the MIT license)

# Copyright (c) 2003 Christian Rees, Janos Demeter, John Matese, Gavin
# Sherlock; Stanford University

# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


# Author : Gavin Sherlock
# Date   : 1st August 2002

# This package is intended to provide some primitive functions to
# provide an abstraction layer to a tab-delimited dataMatrix.  It is
# an abstract class, and requires that concrete subclasses be created
# to take advantage of the functionality.  Such concrete subclasses
# are expected to include a pcl file, and a cdt file.  In many senses,
# tabDelimitedDataMatrix serves as a means for consolidating code that
# would otherwise be duplicated in a pclFile and a cdtFile class.

# This package assumes that a tab-delimited dataMatrix may have
# leading rows of meta data, and/or leading columns of meta data.
# Concrete subclasses will know how to determine how many rows and
# columns of leading meta data there are.


use strict;
use vars qw (@ISA);

$|=1; # set autoflush, so that reporting will flush immediately

use Microarray::DataMatrix::AnySizeDataMatrix;
@ISA = qw (Microarray::DataMatrix::AnySizeDataMatrix);

# CLASS GLOBALS

# use the following so we only ever access hash entries
# using variables, to prevent typos, or accidental cloberring.

# These values are assigned here and then are READ-ONLY.

my $PACKAGE = "Microarray::DataMatrix::TabDelimitedDataMatrix";

my $kMetaDataRecorded = $PACKAGE.'::__metaDataRecorded'; # indicates if meta data recorded
my $kCurrFileDataRow  = $PACKAGE.'::__currFileDataRow';  # which data row we are about to read
my $kColumnNames      = $PACKAGE.'::__columnNames';      # experiment names

######################################################################
sub _numDataRows{
######################################################################
# This method returns the total number of data rows in the tab
# delimited dataMatrix.  The superclass requires that this method be
# implemented in any subclasses, such that the base class can
# determine the number of rows in the matrix, even if the full data
# have not been read in.

    my ($self) = @_;

    my $file = $self->file;

    my $output = `/usr/ucb/wc -l $file`;

    chomp $output;

    $output =~ s/$file//; # get rid of filename from wc output

    $output =~ s/\s+//g;  # get rid of whitespace

    # now subtract the number of leading meta data lines
    # _numLeadingMetaLines is implemented in the concrete subclass

    my $numDataRows = $output - $self->_numLeadingMetaLines; # subtract the number of leading meta data lines

    return ($numDataRows);

}

######################################################################
sub _numDataColumns{
######################################################################
# This method returns the total number of data columns in the
# tab-delimited dataMatrix file.  The base class requires that it be
# implemented in any subclasses, such that the base class can
# determine the number of columns, even if the full data have not been
# read in.

    my ($self) = @_;

    my $file = $self->file;

    if (defined ($self->columnNamesArrayRef)){

	return scalar @{$self->columnNamesArrayRef};

    }else{

	my $fh = $self->_fileHandle(reset=>1);

	# now parse out the headers
	# _parseFileHeaders will be implemented in the concrete subclass

	$self->_parseFileHeaders($fh); # parse out the headers

	$self->_fileHandle(reset=>1); # reset the handle again

	return (scalar @{$self->columnNamesArrayRef});

    }
	
}


######################################################################
sub _dataLine{
######################################################################
# This method reads through the associated tab delimited matrix file,
# and then returns a reference to an array of data that corresponds to
# the requested data line.  A requestedRowNum of zero means the first
# data line.  If no data line corresponds to the requested row number,
# it will return undef.

    my ($self, $requestedRowNum) = @_;

    my $reset = 0; # whether we need to reset the file handle

    if ($self->__currFileDataRow > $requestedRowNum){

	$reset = 1; # we'll have to close and reopen the file
	
    }

    my $fh = $self->_fileHandle(reset=>$reset);

    if ($self->__currFileDataRow == -1){ # we're at the beginning

	# remove the headers from the file

	$self->_parseFileHeaders($fh);

    }

    my $currFileDataRow = $self->__currFileDataRow;

    while ($currFileDataRow < $requestedRowNum){

	# discard data until we reach the correct line

	<$fh> || return undef; # if we read of the end of the file, return undef to indicate no data

	$currFileDataRow++; # increment the count

    }

    # if we get here, the next line to be read is the requested one - phew!

    my $line = <$fh> || return undef; # if we read of the end of the file, return undef to indicate no data

    my $lineRef = $self->_arrayRefForLine(\$line);

    # remove and remember the meta data - this is implemented in the concrete subclass

    $self->_removeMetaDataFromLine($currFileDataRow, $lineRef);

    # set the new line number

    $self->_setCurrFileDataRow($currFileDataRow+1); # use +1 to account for the line we just read

    return $lineRef; # return the data as an array reference

}

######################################################################
sub __currFileDataRow{
######################################################################
# This method is either used to retrieve the current data line number.

    return $_[0]->{$kCurrFileDataRow};

}
    
######################################################################
sub _setCurrFileDataRow{
######################################################################
# This method is used to set the current data line number.

    my ($self, $lineNo) = @_;

    $self->{$kCurrFileDataRow} = $lineNo;

}

######################################################################
sub _arrayRefForLine{
######################################################################
# This method takes a scalar by reference, that is a line from a
# tab delimited file, and returns, by reference, an array that contains
# the chomped and split data from the line.

    my ($self, $lineRef) = @_;

    chomp $$lineRef;

    my @line = split("\t", $$lineRef, -1);

    return \@line;

}


######################################################################
sub _metaDataRecorded{
######################################################################
# This protected method returns a boolean, to indicate whether meta data
# has been recorded for a particular row in the tab delimited file.
#
# Usage : if ($self->_metaDataRecorded($row)){ #blah }

    my ($self, $row) = @_;

    return exists $self->{$kMetaDataRecorded}->{$row};

}

######################################################################
sub _indicateMetaDataRecorded{
######################################################################
# This private method records that meta data has been recorded for a
# particular row in the tab delimited file.  This is so concrete
# subclasses can keep track of whether they already know the meta data
# associated with a line in the file.
#
# Usage : $self->_indicateMetaDataRecordedRecorded($row);

    my ($self, $row) = @_;

    $self->{$kMetaDataRecorded}->{$row} = undef;
    
}

######################################################################
sub columnNamesArrayRef{
######################################################################
# This polymorphic setter/getter method returns a reference to an
# array containing the column names (only of the data columns) from
# the original tab delimited file.  If a new array reference is
# provided, it will rename the columns.
#
# Usage:  
#
#  my $columnNamesArrayRef = $self->columnNamesArrayRef;
#  $self->columnNamesArrayRef($lineRef);

    my ($self, $data) = @_;

    defined ($data) && ($self->{$kColumnNames} = $data);

    return $self->{$kColumnNames};

}

######################################################################
sub _printRow{
######################################################################
# This method is used to print out a row of data to a file.  
#
# Usage : $self->_printRow($fh, $row, $dataRef, $validColumnsArrayRef, $hasExtraInfo, $extraInfoHashRef);
#
# This method prints to the passed in file handle.  It will only print
# information for those valid columns.  If the $extraInfo variable is
# true (ie a non-zero value) it will print the extra info interleaved
# between each column of data.  The extra info comes from the 2D hash
# whose reference is passed in.
   
    my ($self, $fh, $row, $dataRef, $validColumnsArrayRef, $hasExtraInfo, $extraInfoHashRef) = @_;
    
    # first print the meta data for the row (implemented in concrete subclass)

    $self->_printRowMetaData($fh, $row);
    
    # now print our the actual data for the row

    foreach my $column (sort {$a <=> $b } @{$validColumnsArrayRef}){
	
	print $fh "\t", $dataRef->[$column];
	
	$hasExtraInfo && print($fh "\t", $extraInfoHashRef->{$row}{$column});
	
    }
    
    print $fh "\n";
    
}

######################################################################
sub _setFileHandleToStart{
######################################################################
# This method allows the super class file handle method to communicate
# to subclasses that the current file handle is at the beginning of
# the file, so that the subclass can take care of setting/resetting
# any other variables that it might need to.

    my ($self) = @_;

    $self->_setCurrFileDataRow(-1); # reset the current row

}

######################################################################
sub createIndexFile{
######################################################################
# This method creates a simple index file for the
# tabDelimitedDataMatrix.  The index file contains three columns, and
# ID column, which is a sequential number, and the then the UID and
# NAME columns.  These are simply the annotation columns from the
# tabDelimitedDataMatrix.
#
# On the first row, there will be printed the word ID, followed by the
# column name identifiers in the file.
#
# The index file is created for the currently valid rows only.
#
# Usage : $matrix->createIndexFile($filename);
#

    my ($self, $file) = @_;

    open (OUT, ">".$file) || die "Cannot open $file : $!\n";

    print OUT join("\t", ("ID", $self->idName, $self->descName)), "\n";

    my $index = 0;

    foreach my $row (sort {$a<=>$b} @{$self->_validRowsArrayRef}){

	print OUT join("\t", $index, $self->rowName($row), $self->rowDesc($row)), "\n";

	++$index;

    }

    close OUT;

}

######################################################################
sub createRawMatrixFile{
######################################################################
# This method simply creates an unanntotated tab-delimited file that
# contains only the matrix data for those currently valid rows and
# columns, with an index column on the left hand side, staring at
# zero.
#
# Usage : $matrix->createRawMatrixFile($filename);
#

    my ($self, $file) = @_;

    open (OUT, ">".$file) || die "Cannot create raw matrix file, $file : $!";

    my @validColumns = sort {$a<=>$b} @{$self->_validColumnsArrayRef};

    my $index = 0;

    foreach my $row (sort {$a<=>$b} @{$self->_validRowsArrayRef}){

	my $lineRef = $self->_dataLine($row);

	print OUT join ("\t", ($index, @{$lineRef}[@validColumns])), "\n";

	++$index;

    }

    close OUT;
		    
}    

1; # to keep perl happy

=pod

=head2 _dataLine

This method reads through the associated tab delimited file, and then
returns a reference to an array of data that corresponds to the
requested data line.  A requestedRowNum of zero means the first data
line.  If no data line corresponds to the requested row number, it
will return undef.

Usage:

    my $lineRef = $self->_dataLine($num);

=head2 __currFileDataRow

This method is either used to retrieve the current data line number.
It will return -1 if the file being read has had no rows read.

Usage:

    my $currentRow = $self->__currFileDataRow;

=head2 _setCurrFileDataRow

This method is used to set the current data line number.

Usage:

    $self->_setCurrFileDataRow($rowNum);

=head2 _arrayRefForLine

This protected method takes a scalar by reference, that is a line from a tab
delimited file, and returns, by reference, an array that contains the
chomped and split data from the line.

Usage:

    my $lineRef = $self->_arrayRefForLine(\$line);

=head2 _metaDataRecorded

This protected method returns a boolean, to indicate whether meta data
has been recorded for a particular row in the tab delimited file.

Usage : 

    if ($self->_metaDataRecorded($row)){ #blah }

=head2 _indicateMetaDataRecorded

This protected method records that meta data has been recorded for a
particular row in the tab delimited file.

Usage : 

    $self->_indicateMetaDataRecordedRecorded($row);


=head2 columnNamesArrayRef

This polymorphic setter/getter method returns a reference to an array
containing the column names (only of the data columns) from the
original pcl file.  If a new array reference is provided, it will
rename the columns.

Usage:  

    my $columnNamesArrayRef = $self->columnNamesArrayRef;
    $self->columnNamesArrayRef($lineRef);

=head2 _printRow

This method is used to print out a row of data to a file.  It prints
to the passed in file handle.  It will only print information for
those valid columns.  If the $extraInfo variable is true (ie a
non-zero value) it will print the extra info interleaved between each
column of data.  The extra info comes from the 2D hash whose reference
is passed in.  This method is implemented as required by its
superclass, anySizeDataMatrix.

Usage : 

    $self->_printRow($fh, $row, $dataRef, $validColumnsArrayRef, $hasExtraInfo, $extraInfoHashRef);


=head1 AUTHOR

Gavin Sherlock

sherlock@genome.stanford.edu

=cut
