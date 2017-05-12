package Microarray::DataMatrix::BigDataMatrix;

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
# Date   : 10th July 2002

# This package is intended to provide an abstraction layer to a
# dataMatrix whose size is such that all its contents cannot fit
# simultaneously in memory.  It is intended that bigDataMatrix will be
# subclassed by an anySizeDataMatrix object, which is what clients of
# bigDataMatrix will actually see.  It is up to the anySizeDataMatrix
# class itself to determine at runtime whether the matrix used for
# construction is too large to fit in memory.  Thus anySizeDataMatrix
# should have the details about how much memory is available, and a
# means of determing the size of the matrix being used for
# construction.  anySizeDataMatrix can then, at runtime, dynamically
# choose to inherit from bigDataMatrix, or the accompanying
# smallDataMatrix instead.  bigDataMatrix uses temp files to carry out
# tranformations and filterings on a matrix, rather than doing things
# in memory.

use strict;
use Carp;
use vars qw ($AUTOLOAD @ISA);

$| = 1; # set autoflush, so that reporting will flush immediately

# inherit from a base class of dataMatrix

use Microarray::DataMatrix;
@ISA = qw (Microarray::DataMatrix);


####################################################################
#
# CLASS GLOBALS
#
####################################################################

# The following globals are used so we only ever access hash entries
# (ie object attributes) using variables, to prevent typos, or
# accidental clobberring.

# These values are assigned here and then are READ-ONLY.

my $PACKAGE = 'bigDataMatrix'; # will use to prefix all hash entries
                               # which will prevent collision with any
                               # attributes in super or sub classes.

# The following attributes are used to store hashes that track the
# positions of columns and rows in the original file, compared to
# where they may be in a current temporary file.

my $kColumnCurrentToOrig = $PACKAGE.'::__columnCurrentToOrig';
my $kColumnOrigToCurrent = $PACKAGE.'::__columnOrigToCurrent';
my $kRowCurrentToOrig    = $PACKAGE.'::__rowCurrentToOrig';

# other attributes

my $kMaxRowNumber        = $PACKAGE.'::__maxRowNumber';# the max row number in the current file 
my $kTmpNum              = $PACKAGE.'::__tmpNum';      # to keep track of the number of tmp files created
my $kPercentiles         = $PACKAGE.'::__percentiles'; # a hash of the percentiles for the data, if they were requested

# Methods used during initialization

#####################################################################
sub _init{
#####################################################################
# This method will determine the number of rows and columns in the
# matrix, and records their indices as valid.  It MUST be called
# during initialization of a subclass's object, before any other
# methods can be called.

    my ($self) = @_;

    my $numColumns = $self->_numDataColumns;
    my $numRows    = $self->_numDataRows;

    $self->__validateRows($numRows);
    $self->__validateColumns($numColumns);

    $self->__setTmpNum(0);  # initialize our series of temp numbers. 
    $self->__setMaxRowNumber($numRows);

}

######################################################################
sub __validateRows{
######################################################################
# This method receives the number of rows that the matrix has, and simply
# records each one of them as valid.  In addition it sets up a map of
# the row's current position in a temp file, to it's original position 
# in a file.
#
# Usage : $self->__validateRows($numRows);

    my ($self, $numRows) = @_;

    my %validRows;
    
    for (my $i = 0; $i < $numRows; $i++){
	
	$validRows{$i} = undef;
	$self->{$kRowCurrentToOrig}->{$i} = $i;

    }
    
    $self->_setValidRows(\%validRows);

}

######################################################################
sub __validateColumns{
######################################################################
# This method receives the number of columns that the matrix has, and
# simply records each one of them as valid.  In addition it sets up a
# map of the column's position in the original file to its current
# position, and a reverse map of the column's current position, to its
# position in the original file.
#
# Usage : $self->__validateColumns($numColumns);

    my ($self, $numColumns) = @_;

    my %validColumns;
    
    for (my $i = 0; $i < $numColumns; $i++){
	
	$validColumns{$i} = undef;
	$self->{$kColumnCurrentToOrig}->{$i} = $i;
	$self->{$kColumnOrigToCurrent}->{$i} = $i;
	
    }
    
    $self->_setValidColumns(\%validColumns);

}

######################################################################
sub __invalidateMatrixRow{
######################################################################
# This private mutator method makes a row invalid.  We actually do
# the invalidation in the super class, but have to override it here,
# so that we mark the row index from the original file as invalid,
# rather than marking as invalid the row index based on the row's
# current index.  We do this by translating the current row number to
# its original row index.
#
# Usage : $self->__invalidateMatrixRow($num)

    my ($self, $row) = @_;

    $self->SUPER::_invalidateMatrixRow($self->__origRow($row));

}

######################################################################
sub __origRow{
######################################################################
# This private method returns the original row number to which a row in the
# current file now corresponds.
#
# Usage : $self->__origRow($row);

    return $_[0]->{$kRowCurrentToOrig}->{$_[1]};

}

######################################################################
sub __invalidateMatrixColumn{
######################################################################
# This private mutator method makes a column invalid.  We actually do
# the invalidation in the super class, but have to override it here,
# so that we mark the columns index from the original file as invalid,
# rather than marking as invalid the column index based on the column's
# current index.  We do this by translating the current column number
# to its original.
#
# Usage : $self->__invalidateMatrixColumn($column);

    my ($self, $column) = @_;
    
    $self->SUPER::_invalidateMatrixColumn($self->__origColumn($column));

    #delete $self->{$kColumnOrigToCurrent}->{$column}; 

}

######################################################################
sub __origColumn{
######################################################################
# This method returns the original column number to which a column in the
# current file now corresponds
#
# Usage : my $column = $self->__origColumn($column);

    return $_[0]->{$kColumnCurrentToOrig}->{$_[1]};

}

######################################################################
sub __remapRow{
######################################################################
# This private method remaps a line in a tmp file to the line it corresponds
# to in the original file.  It receives the current tmp file line, and
# the number of lines that have been removed before it.  It then
# remaps the current row to point to the original row that the current
# row, $numFilteredLines ahead of it, is pointing to.
#
# Usage : $self->__remapRow($numRowsPrinted, $numFilteredLines)

    my ($self, $row, $numFilteredLines) = @_;

    $self->{$kRowCurrentToOrig}->{$row} = $self->{$kRowCurrentToOrig}->{$row + $numFilteredLines};

}

######################################################################
sub __remapColumn{
######################################################################
# This method remaps a column in a tmp file to the column it
# corresponds to in the original file.  It receives the current file
# column index.  It then remaps the current column to point to the
# original column that the current column, $numFilteredColumns ahead
# of it, is pointing to.
#
# Usage : $self->__remapColumn($numColumnsPrinted, $numFilteredColumns)

    my ($self, $column, $numFilteredColumns) = @_;

    $self->{$kColumnCurrentToOrig}->{$column} = $self->{$kColumnCurrentToOrig}->{$column + $numFilteredColumns};
    
    $self->{$kColumnOrigToCurrent}->{$self->{$kColumnCurrentToOrig}->{$column + $numFilteredColumns}} = $column;

}

######################################################################
sub __remapColumns{
######################################################################
# This method remaps all of the columns in the current tmp file with
# respect to their column index in the original file.  This method
# must be called after carrying out any operation that may reduce the
# number of columns in the matrix.
#
# Usage : $self->__remapColumns;

    my ($self) = @_;

    my $numColumns = $self->numColumns;
    my $numColumnsPrinted = 0;

    my $numFilteredColumns = 0;

    foreach  my $column (sort {$a<=>$b} keys %{$self->{$kColumnCurrentToOrig}}){

	if (!$self->__currentColumnIsValid($column)){

	    $numFilteredColumns++;
	    next;

	}

	$self->__remapColumn($numColumnsPrinted, $numFilteredColumns) if $numFilteredColumns;

	$numColumnsPrinted++;

	last if ($numColumnsPrinted == $numColumns);

    }

}

######################################################################
sub __setMaxRowNumber{
######################################################################
# This method allows recording of the maximum row number that can exist
# in the current file that is being read.

    my ($self, $number) = @_;

    $self->{$kMaxRowNumber} = $number;

}

######################################################################
sub __maxRowNumber{
######################################################################
# This method returns the maximum row number that can exist
# in the current file that is being read.

    return $_[0]->{$kMaxRowNumber};

}

######################################################################
sub __currentRowIsValid{
######################################################################
# This private accessor returns a boolean to indicate whether a given
# row in the tmp file is still valid (ie has not been filtered out).
# It does this by mapping the row to what it's original index was in
# the file used to instantiate the matrix, and then determining
# whether that index is still valid.  
#
# Usage : if ($self->__currentRowIsValid($row)){ # blah }

    my ($self, $row) = @_;

    return $self->_matrixRowIsValid($self->{$kRowCurrentToOrig}->{$row});

}

######################################################################
sub __currentColumnIsValid{
######################################################################
# This private accessor returns a boolean to indicate whether a given
# column in the tmpfile is still valid (ie has not been filtered out).
# It does this by mapping the column to what it's original index was
# in the file used to instantiate the matrix, and then determining
# whether that index is still valid.
#
# Usage : if ($self->__currentColumnIsValid($column)){ # blah }

    my ($self, $column) = @_;

    return $self->_matrixColumnIsValid($self->{$kColumnCurrentToOrig}->{$column});

}

#######################################################################
sub __currentValidColumnsArrayRef{
#######################################################################
# This private method returns an reference to an array that contains
# the indices of the columns that are currently valid in the present
# file.
#
# Usage : my $validColumnsArrayRef = $self->__currentValidColumnsArrayRef;

    my ($self) = @_;

    my @columns;

    foreach my $column (sort {$a<=>$b} keys %{$self->{$kColumnOrigToCurrent}}){

	push (@columns, $self->{$kColumnOrigToCurrent}->{$column}) if $self->_matrixColumnIsValid($column);

    }

    return \@columns;

}

######################################################################
sub __currentValidRowsArrayRef{
######################################################################
# This private method returns an reference to an array that contains
# the indices of the rows that are currently valid in the present file
#
# Usage : foreach (@{$self->__currentValidRowsArrayRef}){ # blah }

    my ($self) = @_;

    my @rows;

    my $maxRowNum = $self->__maxRowNumber;

    foreach my $row (sort {$a<=>$b} keys %{$self->{$kRowCurrentToOrig}}){

	# a row number should not be valid if it is higher than the
	# maximum allowable row index.  Because invalidation does not
	# deal with this 100%, this extra check here does.

	push (@rows, $row) if ($row < $maxRowNum && $self->__currentRowIsValid($row));

    }

    return \@rows;

}

######################################################################
sub __currentColumnForOrig{
######################################################################
# This method returns the index where a column in the original file,
# now maps in the current temp file.
#
# Usage : my $col = $self->__currentColumnForOrig($column);

    return $_[0]->{$kColumnOrigToCurrent}->{$_[1]};

}

######################################################################
sub __tmpFileHandle{
######################################################################
# This private method returns a handle to a tmpfile.  If given a 'new'
# argument, which will be passed to the tmpFile method, the file will
# have it's number increased by one - ie a new file will be used.
# Otherwise, a previously created file will be opened.
#
# Usage : my $fh = $self->__tmpFileHandle(new=>1);

    my ($self, %args) = @_;

    my $tmpFile = $self->__tmpFile(%args);

    local *FH;
	
    open(FH, ">$tmpFile") || die "Couldn't open $tmpFile : $!\n"; # need an error handling strategy here
    		
    my $fh = *FH;

    return $fh;

}

######################################################################
sub __tmpFile{
######################################################################
# This method returns the name of a tmpfile.  If given the 'new'
# argument then the name will be of a new file.  Otherwise it will be
# of the last generated tmpfile.
#
# Usage : my $tmpFile = $self->__tmpFile(new=>1);

    my ($self, %args) = @_;

    my $num = $self->__tmpNum;

    if ($args{'new'}){

	$num++;

	$self->__setTmpNum($num);

    }

    return ($self->_tmpDir.'matrix.'.$$.'.'.$num);	

}

######################################################################
sub __tmpNum{
######################################################################
# This method returns the number of the temp file.  Generally this
# number should be incremented by 1 each time a new tmp file is
# created.
#
# Usage : my $num = $self->__tmpNum;


    return $_[0]->{$kTmpNum};    

}

######################################################################
sub __setTmpNum{
######################################################################
# This method allows the tmp num to be set.
#
# Usage : $self->__setTmpNum($num);

    my ($self, $num) = @_;

    $self->{$kTmpNum} = $num;

}

#
# ** DATA TRANSFORMATION METHODS
#

######################################################################
sub _centerColumns{
######################################################################
# This private method centers each column of data, and returns the
# largest absolute value that was used in centering.
#
# This version of the method assumes that all data for the matrix are
# too large to fit in memory
#
# if we are calculating medians, we have to deal with it differently
# than if we are centering columns by means.  This is because to
# calculate medians we need to store data in memory and sort it to
# find the median, whereas for means we can simply keep running totals
# in memory.  Thus to do it by medians, we will have to read the file
# several times.  Thus I will seperate out these methods into two functions.

    my ($self, $method, $lineEnding, $numColumnsToReport) = @_;
    
    defined $lineEnding && print ("Centering columns by $method", $lineEnding);
    
    my $methodCall = "__centerColumns_".$method;
    
    my $largestVal = $self->$methodCall($lineEnding, $numColumnsToReport, $self->_numRowsToReport);

    return $largestVal;
    
}

######################################################################
sub __centerColumns_mean{
######################################################################
# This method is used for centering the columns of a dataset by the 
# mean value, when the contents of the dataset are too large to all fit
# in memory.
#
# Usage : my $largestVal = $self->__centerColumns_mean($lineEnding, $numColumnsToReport, $numRowsToReport);

    my ($self, $lineEnding, $numColumnsToReport, $numRowsToReport) = @_;

    my $largestVal = 0;

    my $num = -1;

    my (@totals, @numDataPoints, @means);

    # first read through all data, and calculate totals for each column

    while (my $lineRef = $self->_dataLine($num+1)){

	$num++;
	
	next if !$self->__currentRowIsValid($num);
	
	if (defined $lineEnding && !($num%$numRowsToReport)){
	    
	    print "Reading data for row $num", $lineEnding;
	    
	}
	
	my $numDatapoints = 0;
	
	for (my $i = 0; $i< @{$lineRef}; $i++){ # go through each data value

	    next if (!$self->__currentColumnIsValid($i)|| $lineRef->[$i] eq ""); # skip blanks and invalid columns

	    $totals[$i] += $lineRef->[$i]; # keep running sum
	    $numDataPoints[$i]++;

	}

    }

    # now calculate the means

    for (my $i = 0; $i < @totals; $i++){

	next if (!defined $numDataPoints[$i]); # they may simply have filler columns, with no data
	
	$means[$i] = $totals[$i]/$numDataPoints[$i];
	
	if (abs($means[$i]) > $largestVal){
	    
	    $largestVal = abs($means[$i]);	    
	    
	}
	
    }
    
    # now we have to actually center the data, by going through the
    # data again and creating a new file with the means subtracted.
    # This can be put in another function, that can be used by the
    # centerColumnMedians as well

    $self->__subtractColumnAverages(\@means, $lineEnding, $numColumnsToReport, $numRowsToReport); 

    return $largestVal;
    
}


######################################################################
sub __centerColumns_median{
######################################################################
# This method is used for centering the columns of a dataset by the 
# median value, when the contents of the dataset are too large to all fit
# in memory.
#
# Because we need to have a sorted list of values to calculate the 
# median, we are going to have to read through all the data multiple
# times (potentially).
#
# Usage : my $largestVal = $self->__centerColumns_median($lineEnding, $numColumnsToReport, $numRowsToReport);

    my ($self, $lineEnding, $numColumnsToReport, $numRowsToReport) = @_;

    my $largestVal = 0;

    my $numColumns = $self->_numDataColumns; # get info from subclass
    my $numRows   = $self->_numDataRows; # to decide on the fly how many columns we can read

    # now get data for a certain number of columns at a time

    my $numColumnsToProcess = int(500000/$numRows); # assume if 50,000 rows, can process 10 columns at a time

    if ($numColumnsToProcess > $numColumns){

	$numColumnsToProcess = $numColumns;

    }

    my @medians;

    for (my $i = 0; $i < $numColumns; $i+= $numColumnsToProcess){

	if (defined $lineEnding){

	    print "Processing columns $i through ", $i + $numColumnsToProcess, $lineEnding;

	}

	my $num = -1;

	my @values;

	my $lastIndex; # the index of the last data column to process in this round

	if ($i + $numColumnsToProcess > $numColumns){

	    $lastIndex = $numColumns;

	}else{

	    $lastIndex = $i + $numColumnsToProcess;

	}

	while (my $lineRef = $self->_dataLine($num+1)){
	    
	    $num++;

	    next if !$self->__currentRowIsValid($num);

	    if (defined $lineEnding && !($num%$numRowsToReport)){
		
		print "Reading data for row $num", $lineEnding;
		
	    }
	    
	    my $col = -1;
	    
	    for (my $j = $i; $j < $lastIndex; $j++){ # go through each data value

		$col++;
		
		next if (!$self->__currentColumnIsValid($j) || $lineRef->[$j] eq ""); # skip invalid columns and blanks

		push (@{$values[$col]}, $lineRef->[$j]);
		
	    }
		
	}

	# now get the median value for each of those columns

	my $col = -1;

	for (my $j = $i; $j < $lastIndex; $j++){ # go through each column of data

	    $col++;

	    next if (!$self->__currentColumnIsValid($j) || !defined $values[$col]); # skip invalid columns, or columns with no data
	    
	    my $median = $self->_average("median", $values[$col]);

	    if (abs($median) > $largestVal){

		$largestVal = abs($median);

	    }

	    $medians[$j] = $median;

	}

    }

    # once we get here, we should have calculate the median for every column
    # so now need to subtract them from every column

    $self->__subtractColumnAverages(\@medians, $lineEnding, $numColumnsToReport, $numRowsToReport); 

    return $largestVal;

}

######################################################################
sub __subtractColumnAverages{
######################################################################
# This method retrieves data from the dataMatrix through the subclass,
# subtracts the column average from each value, then, through the subclass
# writes out a new file.
#
# Usage : $self->__subtractColumnAverages(\@medians, $lineEnding, $numColumnsToReport); 
#
# Note we're not worrying here about percentiles being dumped out

    my ($self, $averagesArrayRef, $lineEnding, $numColumnsToReport, $numRowsToReport) = @_;
    
    my $num = -1;
    my $numFilteredLines = 0; # keep a record of how many lines are filtered out
    my $numRowsPrinted = 0;

    my $validColumnsArrayRef = $self->__currentValidColumnsArrayRef;

    my $hasPercentiles;
    my $percentilesHashRef; # have to worry about
    
    # first open a new file, and dump out the meta data
    
    my $fh = $self->__tmpFileHandle(new=>1);
    
    $self->_printLeadingMeta($fh, $self->_validColumnsArrayRef);
    
    # go through all data, and subtract average
    
    while (my $lineRef = $self->_dataLine($num+1)){
	
	$num++;
	
	if (!$self->__currentRowIsValid($num)){
	    
	    $numFilteredLines++; 
	    next; # don't print this line out

	}
	
	if (defined $lineEnding && !($num%$numRowsToReport)){
	    
	    print "Subtracting column averages from row $num", $lineEnding;
	    
	}
	
	for (my $i = 0; $i< @{$lineRef}; $i++){ # go through each data value

	    next if $lineRef->[$i] eq ""; # skip blanks

	    $lineRef->[$i] -= $averagesArrayRef->[$i];

	}

	# now we want to dump the data line to disk

	$self->_printRow($fh, $self->__origRow($num), $lineRef, $validColumnsArrayRef);

	# if any lines have been filtered, we need to remap the current row

	$self->__remapRow($numRowsPrinted, $numFilteredLines) if $numFilteredLines;

	$numRowsPrinted++;

    }

    # now dump out any trailing meta data, then close the handle
    
    $self->_printTrailingMeta($fh, $self->_validColumnsArrayRef);

    close $fh;

    $self->_setFileForReading($self->__tmpFile);

    $self->__remapColumns;

    $self->__setMaxRowNumber($self->numRows);

}

 
######################################################################
sub _centerRows{
######################################################################
# This private method actually centers the row data.  This version assumes
# that all data are too big to fit in memory.

    my ($self, $method, $lineEnding, $numRowsToReport) = @_;

    defined $lineEnding && print ("Centering rows by $method", $lineEnding);

    my $fh = $self->__tmpFileHandle(new=>1);

    my $validColumnsArrayRef = $self->__currentValidColumnsArrayRef;

    $self->_printLeadingMeta($fh, $self->_validColumnsArrayRef);

    my $num = -1;

    while (my $lineRef = $self->_dataLine($num+1)){

	$num++;

	next if !$self->__currentRowIsValid($num);
	
    	if (defined $lineEnding && !($num%$numRowsToReport)){
	    
	    print "Centering row $num", $lineEnding;
	    
	}
	
	my $average = $self->_rowAverage($lineRef, $method);

	# now subtract average from each value

	$self->_centerRow($lineRef, $average);
	
	# now we want to dump the data line to disk

	$self->_printRow($fh, $self->__origRow($num), $lineRef, $validColumnsArrayRef);

    }

    # now dump out any trailing meta data, then close the handle
    
    $self->_printTrailingMeta($fh, $self->_validColumnsArrayRef);

    close $fh;

    $self->_setFileForReading($self->__tmpFile);

    $self->__remapColumns;

    $self->__setMaxRowNumber($self->numRows);

}

######################################################################
sub _filterRowsByPercentPresentData{
######################################################################
# This method invalidates rows that do not have greater than the
# requested percentage of present data.

    my ($self, $percent, $lineEnding, $numRowsToReport) = @_;
    
    my $requiredNumDatapoints = $self->numColumns * ($percent / 100);
    
    my $num = -1;

    while (my $lineRef = $self->_dataLine($num+1)){
	
	$num++;

	next if !$self->__currentRowIsValid($num);

	if (defined $lineEnding && !($num%$numRowsToReport)){
	    
	    print "Filtering row $num", $lineEnding;
	    
	}

	my $numDatapoints = 0;
	
	foreach (my $i = 0; $i < @{$lineRef}; $i++){ # go through each data value
	    
	    next if (!$self->__currentColumnIsValid($i) || $lineRef->[$i] eq "");
	    
	    $numDatapoints++;
	    
	}

	$self->__invalidateMatrixRow($num) unless ($numDatapoints > $requiredNumDatapoints);

    }
	
}

######################################################################
sub _filterColumnsByPercentPresentData{
######################################################################
# This method invalidates columns that do not have greater than the
# requested percentage of present data
#
# This version of the method is for when all data are too large fit in memory.

    my ($self, $percent, $lineEnding, $numColumnsToReport) = @_;

    my $numRowsToReport = $self->_numRowsToReport;

    my $requiredNumDatapoints = $self->numRows * ($percent / 100);

    my $num = -1;

    my @totals;

    while (my $lineRef = $self->_dataLine($num+1)){
	
	$num++;

	next if !$self->__currentRowIsValid($num);

	if (defined $lineEnding && !($num%$numRowsToReport)){
	    
	    print "Reading data for row $num", $lineEnding;
	    
	}

	# now keep a tally of the number of datapoints per column
	
	my $numDatapoints = 0;
	
	for (my $i  = 0; $i < @{$lineRef} ; $i++){

	    next if (!$self->__currentColumnIsValid($i) || $lineRef->[$i] eq "");

	    $totals[$i]++;

	}

    }
	
    for (my $i = 0; $i < @totals; $i++){

	next if !$self->__currentColumnIsValid($i);

	$self->__invalidateMatrixColumn($i) unless (defined ($totals[$i]) && $totals[$i] > $requiredNumDatapoints);

    }	    

}
##############################################################################################
sub _filterRowsOnColumnPercentile{
##############################################################################################
# This method filters out rows based on their column percentile, when all data are too BIG
# to fit in memory simultaneously

    die "_filterRowsOnColumnPercentile is not implemented for big datamatrices.";

}

######################################################################
sub __filterRowsByCount{
######################################################################
# This private method filters out rows that don't have a count for
# some particular property above or equal to a threshold.  It accepts
# a hash reference, that hashes the row number to a count, and a
# threshold value.  Note that not all rows are necessarily entered
# into the hash, so this method iterates over all rows, and checks
# each valid one for its count in the hash, then invalidates those
# with too low a count.
#
# Usage : $self->__filterRowsByCount(\%count, $numColumns);

    my ($self, $rowToCountHashRef, $threshold) = @_;

    foreach my $row (sort {$a<=>$b} @{$self->__currentValidRowsArrayRef}){

	if (!exists($rowToCountHashRef->{$row}) || $rowToCountHashRef->{$row} < $threshold){

	    $self->__invalidateMatrixRow($row);

	}	    

    }

}

########################################################################
sub _filterRowsOnColumnDeviation{
########################################################################
# This method will filter out rows whose values do not deviate from
# the column mean by a specified number of standard deviations, in at
# least numColumns columns.  This version of the method is written
# for the case when all data are too large to fit in memory
#

    my ($self, $lineEnding, $numRowsToReport, $deviations, $numColumns) = @_;

    # first need to get the standard deviations of all valid columns

    my ($stddevHashRef, $meansHashRef) = $self->__validColumnsStdDevAndMeanHashRefs($lineEnding, $numRowsToReport);
    
    # now calculate the upper and lower bounds for each column

    my ($upperHashRef, $lowerHashRef) = $self->_calculateBounds($stddevHashRef, $meansHashRef, $deviations, $lineEnding);

    # now count up how many values in each row lie outside of the
    # specified number of deviations from the mean, for each row

    my (%count, $val);

    # go through every row

    defined $lineEnding && print("Running filters over each row", $lineEnding);

    my $num = -1;

    while (my $lineRef = $self->_dataLine($num+1)){
	
	$num++;

	next if !$self->__currentRowIsValid($num);    

	if (defined $lineEnding && !($num%$numRowsToReport)){

	    print "Filtering row $num", $lineEnding;
	    
	}

	foreach (my $column = 0; $column < @{$lineRef}; $column++){

	    next if !$self->__currentColumnIsValid($column);

	    $val = $lineRef->[$column];

	    next if ($val eq "");

	    next unless ($val > $upperHashRef->{$column} || $val < $lowerHashRef->{$column});

	    $count{$num}++; # this value passes the criteria

	}

    }

    $self->__filterRowsByCount(\%count, $numColumns);

}

######################################################################
sub __validColumnsStdDevAndMeanHashRefs{
######################################################################
# This method calculates the standard deviations for each valid
# column, and returns references to two hashes.  Both have the column
# index as the key, and one has the standard deviation as the values,
# the other has the column means as the values.
#
# mean = Sum of values/n
# std dev = square root (((n * sum of (x^2)) - (sum of x)^2)/n(n-1))
#
# Usage : my ($stddevHashRef, $meansHashRef) = $self->__validColumnsStdDevAndMeanHashRefs($lineEnding);

    my ($self, $lineEnding, $numRowsToReport) = @_;

    my (%sumOfX, %sumX2, %numDataPoints, $val);

    defined $lineEnding && print ("Calculating mean and standard deviations for each column", $lineEnding);

    my $num = -1;

    while (my $lineRef = $self->_dataLine($num+1)){
	
	$num++;

	if (defined $lineEnding && !($num%$numRowsToReport)){

	    print "Processing row $num", $lineEnding;

	}

	next if !$self->__currentRowIsValid($num);

	for (my $column = 0; $column < @{$lineRef}; $column++){

	    next if !$self->__currentColumnIsValid($column);

	    $val = $lineRef->[$column];

	    next if ($val eq "");

	    $sumOfX{$column} += $val;
	    $sumX2{$column}  += $val*$val;
	    $numDataPoints{$column}++;

	}

    }

    my ($stddevHashRef, $meansHashRef) = $self->_calculateMeansAndStdDeviations(\%sumOfX, \%sumX2, \%numDataPoints);

    return ($stddevHashRef, $meansHashRef);

}

######################################################################
sub _filterRowsOnValues{
######################################################################
# This method filters out rows whose values do not pass a specified
# criterion, in at least numColumns columns.  This is the version for
# when all data cannot fit in memory
#

    my ($self, $value, $method, $lineEnding, $numRowsToReport, $numColumns) = @_;

    my (%count, $datum);

    my $num = -1;

    while (my $lineRef = $self->_dataLine($num+1)){

	$num++;

	if (defined $lineEnding && !($num%$numRowsToReport)){

	    print "Filtering row $num", $lineEnding;

	}
	
	next if !$self->__currentRowIsValid($num);
	
	for (my $column = 0; $column < @{$lineRef}; $column++){

	    next if !$self->__currentColumnIsValid($column);

	    $datum = $lineRef->[$column];

	    next if $datum eq "";

	    # following method call returns true if value passes criteria

	    $count{$num}++ if ($self->$method($datum, $value));

	}
	
    }    

    $self->__filterRowsByCount(\%count, $numColumns);
	    
}

######################################################################
sub _filterRowsOnVectorLength{
######################################################################
# This method filters out rows based on whether the vector that their
# values define has a length of greater than the specified length.
#

    my ($self, $requiredLength, $lineEnding, $numRowsToReport) = @_;

    my $val;

    my $num = -1;

    while (my $lineRef = $self->_dataLine($num+1)){

	$num++;

	next if (!$self->__currentRowIsValid($num));

	if (defined $lineEnding && !($num%$numRowsToReport)){

	    print "Filtering row $num", $lineEnding;

	}

	my $sumSquares;

	foreach (my $column = 0; $column <@{$lineRef}; $column++){

	    next if !$self->__currentColumnIsValid($column);
    
	    $val = $lineRef->[$column];

	    next if $val eq "";
	    
	    $sumSquares += $val**2;
	    
	}
	
	# invalidate those who don't pass the length requirement
	
	$self->__invalidateMatrixRow($num) unless sqrt($sumSquares) > $requiredLength;
	
    }

}


######################################################################
sub _logTransformData{
######################################################################
# This method log transforms the contents of the data matrix, using
# the specified base.  
# 
# This version is for when all data cannot fit in memory

    my ($self, $logBase, $lineEnding, $numRowsToReport) = @_;

    my ($val);

    my $fh = $self->__tmpFileHandle(new=>1);

    my $validColumnsArrayRef = $self->__currentValidColumnsArrayRef;

    $self->_printLeadingMeta($fh, $self->_validColumnsArrayRef);

    my $num = -1;

    while (my $lineRef = $self->_dataLine($num+1)){

	$num++;

	next if !$self->__currentRowIsValid($num);

	if (defined $lineEnding && !($num%$numRowsToReport)){

	    print "Log transforming row $num", $lineEnding;

	}

	foreach (my $column = 0; $column < @{$lineRef}; $column++){

	    next if !$self->__currentColumnIsValid($column);

	    $val = $lineRef->[$column];
	    
	    next if (!defined $val || $val eq ""); # skip blanks

	    $lineRef->[$column] = sprintf "%.4f", log($val)/$logBase;

	}

	$self->_printRow($fh, $self->__origRow($num), $lineRef, $validColumnsArrayRef);

    }

    # now dump out any trailing meta data, then close the handle
    
    $self->_printTrailingMeta($fh, $self->_validColumnsArrayRef);

    close $fh;

    $self->_setFileForReading($self->__tmpFile);

    $self->__remapColumns; # do we need to do this?

    $self->__setMaxRowNumber($self->numRows);

}

######################################################################
sub _scaleColumnData{
######################################################################
# This method scales the data for particular columns as specified by
# the client, when all data are too big to fit in memory.
#

    my ($self, $columnsToFactorsHashRef, $lineEnding, $numRowsToReport) = @_;

    my $num = -1;

    my ($val, $scalingFactor, $printed1, $printed2);

    my $fh = $self->__tmpFileHandle(new=>1);

    my $validColumnsArrayRef = $self->__currentValidColumnsArrayRef;

    $self->_printLeadingMeta($fh, $self->_validColumnsArrayRef);

    while (my $lineRef = $self->_dataLine($num+1)){

	$num++;

	next if !$self->__currentRowIsValid($num);

	if (defined $lineEnding && !($num%$numRowsToReport)){

	    print "Scaling column data on row $num", $lineEnding;

	}

	foreach my $column (keys %{$columnsToFactorsHashRef}){

	    if (!$self->_matrixColumnIsValid($column)){

		if (!defined ($printed1)){

		    print STDERR "The column index, $column, is not valid for this dataMatrix.\n";

		}

		$printed1 = 1; # so we only print message once
		next;
		
	    }

	    $scalingFactor = $columnsToFactorsHashRef->{$column};

	    if (!defined $scalingFactor || $scalingFactor == 0){

		if (!defined $printed2){

		    print STDERR "The scaling factor supplied for $column was \"$scalingFactor\".\n";
		    print STDERR "It will not be used.\n";
		    
		}

		$printed2 = 1; # so we only print message once
		next;

	    }
			    
	    $val = $lineRef->[$self->__currentColumnForOrig($column)];

	    next if $val eq ""; # skip blanks

	    $lineRef->[$self->__currentColumnForOrig($column)] =  sprintf "%.4f", $val/$scalingFactor;

	}

	$self->_printRow($fh, $self->__origRow($num), $lineRef, $validColumnsArrayRef);

    }

    # now dump out any trailing meta data, then close the handle
    
    $self->_printTrailingMeta($fh, $self->_validColumnsArrayRef);

    close $fh;

    $self->_setFileForReading($self->__tmpFile);

    $self->__remapColumns; # do we need to do this?

    $self->__setMaxRowNumber($self->numRows);

}


######################################################################
sub dumpData{
######################################################################
# This method dumps the current contents of the dataMatrix object to a
# file, either whose name was provided as a single argument, or to a
# file whose name was used to construct the object.
#
# To do this, it delegates printing to a subclass.
# Subclasses have to implement the following methods:
#
# _printLeadingMeta
# _printRow
# _printTrailingMeta
#
# printLeadingMeta is given a reference to an array of the valid columns
# printRow is given a row number, and the VALID data for that row
# printTrailingMeta is given a reference to an array of the valid columns array of the valid columns
#
# is there is no leading or trailing meta information to print,
# the subclass can leave the subroutines empty.......

    my ($self, $file) = @_;

    # As the matrix did not fit in memory, we may need to use the
    # original file to read in the data, if we do not have our own tmp
    # file, and if no filename was provided, as it is the only source
    # of the data

    if (!$self->__tmpNum && !$file){

	my $tmpFile = $self->__tmpFile(new=>1);

	# we can simply rename the file, as the user wants it overwritten anyway

	rename ($self->file, $tmpFile);

	# need to tell the subclass that the file for reading has had its name changed

	$self->_setFileForReading($tmpFile);

    }

    my $remove = $file; # if a file name was passed in, we'll be allowed to remove the last temp file.

    $file ||= $self->file;

    if (defined $self->_fileForReading && $file eq $self->_fileForReading){ # don't want to clobber ourselves

	my $tmpFile = $self->__tmpFile(new=>1);

	# we can simply rename the file, as the user wants it overwritten anyway

	rename ($self->_fileForReading, $tmpFile);

	# need to tell the subclass that the file for reading has had its name changed

	$self->_setFileForReading($tmpFile);

    }

    my $hasPercentiles = exists $self->{$kPercentiles};

    my $percentilesRef = $self->{$kPercentiles};

    open (DATAOUT, ">$file") || die "Cannot open $file for writing : $!.\n";

    # print first line    

    $self->_printLeadingMeta(\*DATAOUT, $self->_validColumnsArrayRef, $hasPercentiles, "percentiles");
    
    my $row = -1;
    my $numFilteredLines = 0; # keep a record of how many lines are filtered out
    my $numRowsPrinted = 0;

    my $currentValidColumnsArrayRef = $self->__currentValidColumnsArrayRef;

    while (my $lineRef = $self->_dataLine($row+1)){
	
	$row++;
	
	if (!$self->__currentRowIsValid($row)){
	    
	    $numFilteredLines++; 
	    next; # don't print this line out
	    
	}
	
	$self->_printRow(\*DATAOUT, $self->__origRow($row), $lineRef, $currentValidColumnsArrayRef, $hasPercentiles, $percentilesRef);

	# if any lines have been filtered, we need to remap the current row

	$self->__remapRow($numRowsPrinted, $numFilteredLines) if $numFilteredLines;

	$numRowsPrinted++; # do this last, as we call the first line zero
	
    }

    $self->__remapColumns;
    
    $self->_printTrailingMeta(\*DATAOUT, $self->_validColumnsArrayRef, $hasPercentiles);

    close DATAOUT;

    $self->_setFileForReading($file);

    $remove && unlink($self->__tmpFile);

    $self->__setMaxRowNumber($self->numRows);

}


1; # to keep Perl happy

=pod

=head1 NAME

Microarray::DataMatrix::BigDataMatrix - abstraction to matrix that won't fit in memory

=head1 Abstract

bigDataMatrix is an abstract class, which provides as abstraction to a
matrix of data that is too large to fit into memory.  It should not be
subclassed by concrete subclasses.  Instead, the subclass
anySizeDataMatrix, can be subclassed with concrete subclasses, which
will provide abstractions to dataMatrices stored in particular file
formats, such as pcl files.

=head1 Overall Logic

Internally, bigDataMatrix simply keeps track of which rows and columns
are still valid.  As it runs filters, or transformations on data, it
creates temp files, which contain the result of such an operation.  It
keeps track of which rows and columns in the latest temp file are
valid, and also to which rows and columns in the original file, used
for object construction, that they map.  Then, when it comes time to
dump data to disk, it is able to instruct a concrete subclass what the
original index of a row or column was, so that the concrete subclass
can print out the appropriate meta data.

=head1 Construction

As bigDataMatrix is an abstract class, it has no constructor.
However, the subclass, anySizeDataMatrix, once it has determined that
a matrix will not fit into memory, MUST call the _init method, which
is described below.

=head2 _init

This protected method will read determine how many rows and columns
there are in the initial matrix.  It MUST be called during
initialization of a subclass object, before any other methods can be
called by the client (in practice it is called from anyDataMatrix).

Usage:

    $self->_init;

or:

    $self->SUPER::_init;

=head1 private utility methods

=head2 __validateRows

This private method receives the number of rows that the matrix has,
and simply records each one of them as valid.  In addition it sets up
a map of the current row positions in a temp file, to their original
positions in the file used for construction.

Usage:

    $self->__validateRows($numRows);

=head2 __validateColumns

This method receives the number of columns that the matrix has, and
simply records each one of them as valid.  In addition it sets up a
map of the column positions in the original file to their current
positions, and a reverse map of the columns current positions, to
their positions in the original matrix file used for object
construction.

Usage : 

    $self->__validateColumns($numColumns);

=head2 __invalidateMatrixRow

This private mutator method makes a row invalid.  We actually do the
invalidation in the super class, but have to use this method to call
the superclass method, so that we mark the row index from the original
file as invalid, rather than marking as invalid the row index based on
the rows current index.  We do this by translating the current row
number to its original row index.

Usage :

    $self->__invalidateMatrixRow($num);

=head2 __origRow

This private method returns the original row number to which a row in
the current file now corresponds.

Usage : 

    my $origRow = $self->__origRow($row);

=head2 __invalidateMatrixColumn

This private mutator method makes a column invalid.  We actually do
the invalidation in the super class, but have to use this method to
call the superclass method, so that we mark the columns index from the
original file as invalid, rather than marking as invalid the column
index based on the current index of a column.  We do this by translating
the current column number to its original.

Usage : 
    
    $self->__invalidateMatrixColumn($column);

=head2 __origColumn

This method returns the original column number to which a column in
the current file now corresponds.

Usage : 

    my $column = $self->__origColumn($column);

=head2 __remapRow

This private method remaps a line in a tmp file to the line it corresponds
to in the original file.  It receives the current tmp file line, and
the number of lines that have been removed before it.  It then
remaps the current row to point to the original row that the current
row, $numFilteredLines ahead of it, is pointing to.

Usage : 

    $self->__remapRow($numRowsPrinted, $numFilteredLines);

=head2 __remapColumn

This private method remaps a column in a tmp file to the column it
corresponds to in the original file.  It receives the current file
column index.  It then remaps the current column to point to the
original column that the current column, $numFilteredColumns ahead of
it, is pointing to.

Usage : 

    $self->__remapColumn($numColumnsPrinted, $numFilteredColumns);

=head2 __remapColumns

This method remaps all of the columns in the current tmp file with
respect to their column index in the original file.  This method must
be called after carrying out any operation that may reduce the number
of columns in the matrix.

Usage : 

    $self->__remapColumns;

=head2 __currentRowIsValid

This private accessor returns a boolean to indicate whether a given
row in the tmp file is still valid (ie has not been filtered out).  It
does this by mapping the row to what its original index was in the
file used to instantiate the matrix, and then determining whether that
index is still valid.

Usage : 

    if ($self->__currentRowIsValid($row)){ # blah }

=head2 __currentColumnIsValid

This private accessor returns a boolean to indicate whether a given
column in the tmpfile is still valid (ie has not been filtered out).
It does this by mapping the column to what its original index was
in the file used to instantiate the matrix, and then determining
whether that index is still valid.

Usage : 

    if ($self->__currentColumnIsValid($column)){ # blah }

=head2 __currentValidColumnsArrayRef

This private method returns an reference to an array that contains the
indices of the columns that are currently valid in the present file.

Usage : 

    my $validColumnsArrayRef = $self->__currentValidColumnsArrayRef;

=head2 __currentValidRowsArrayRef

This private method returns an reference to an array that contains the
indices of the rows that are currently valid in the present file

Usage : 

    foreach (@{$self->__currentValidRowsArrayRef}){ # blah }

=head2 __currentColumnForOrig

This method returns the index where a column in the original file,
now maps in the current temp file.

Usage : 

    my $col = $self->__currentColumnForOrig($column);

=head2 __tmpFileHandle

This private method returns a handle to a tmpfile.  If given a 'new'
argument, which will be passed to the tmpFile method, the file will
have its associated number increased by one - ie a new file will be
used.  Otherwise, a previously created file will be opened.

Usage : 

    my $fh = $self->__tmpFileHandle(new=>1);

=head2 __tmpFile

This private method returns the name of a tmpfile.  If given the 'new'
argument then the name will be of a new file.  Otherwise it will be of
the last generated tmpfile.

Usage : 

    my $tmpFile = $self->__tmpFile(new=>1);

=head2 __tmpNum

This method returns the number of the temp file.  Generally this
number should be incremented by 1 each time a new tmp file is created.

Usage : 

    my $num = $self->__tmpNum;

=head2 __setTmpNum

This method allows the tmp num to be set.

Usage : 

    $self->__setTmpNum($num);

=head2 __centerColumns_mean

This private method is used for centering the columns of a dataset by
the mean value.

Usage : 

    my $largestVal = $self->__centerColumns_mean($lineEnding, $numColumnsToReport);

=head2 __centerColumns_median

This method is used for centering the columns of a dataset by the
median value.

Because we need to have a sorted list of values to calculate the 
median, we are going to have to read through all the data multiple
times (potentially), to avoid having to have too much data in memory.

Usage : 

    my $largestVal = $self->__centerColumns_median($lineEnding, $numColumnsToReport);

=head2 __subtractColumnAverages

This method retrieves data from the dataMatrix through the subclass,
subtracts the column average from each value, then, through the
subclass methods writes out a new file.

Usage : 

    $self->__subtractColumnAverages(\@medians, $lineEnding, $numColumnsToReport); 

=head2 __filterRowsByCount

This private method filters out rows that do not have a count for some
particular property above or equal to a threshold.  It accepts a hash
reference, that hashes the row number to a count, and a threshold
value.  Note that not all rows are necessarily entered into the hash,
so this method iterates over all rows, and checks each valid one for
its count in the hash, then invalidates those with too low a count.

Usage : 

    $self->__filterRowsByCount(\%count, $numColumns);

=head2 __validColumnsStdDevAndMeanHashRefs

This method calculates the standard deviations for each valid column,
and returns references to two hashes.  Both have the column index as
the key, and one has the standard deviation as the values, the other
has the column means as the values.

    mean = Sum of values/n
    std dev = square root (((n * sum of (x^2)) - (sum of x)^2)/n(n-1))

Usage : 

    my ($stddevHashRef, $meansHashRef) = $self->__validColumnsStdDevAndMeanHashRefs($lineEnding);

=head1 Protected data transformation/filtering methods

Note: These methods provide the backend nuts and bolts for a
transformation or filtering.  They should only be called by the
immediate subclass, anySizeDataMatrix, and not directly by the
concrete subclasses of anySizeDataMatrix.  In addition, note that the
companion smallDataMatrix must (and does) provide identical interfaces
to these methods (obviously with different underlying
implementations), such that anySizeDataMatrix can call the methods
without regard to the size of the underlying matrix.

=head2 _centerColumns

This protected method centers each column of data, and returns the
largest absolute value that was used in the centering.  The caller of
the method must specify whether to center by means or medians.

Usage :

    $self->_centerColumns('mean', $lineEnding, $numColumnsToReport);

=head2 _centerRows

This protected method actually centers the row data, by calculating
the average (mean or nedian, depending on what was requested) for each
row, and then subtracting that value from each valid datapoint in the
row.

Usage :

    $self->_centerRows('median', $lineEnding, $numRowsToReport);

=head2 _filterRowsByPercentPresentData

This protected method invalidates rows that do not have greater than
the requested percentage of present data.

Usage : 

    $self->_filterRowsByPercentPresentData($percent, $lineEnding, $numRowsToReport);

=head2 _filterColumnsByPercentPresentData

This protected method invalidates columns that do not have greater
than the requested percentage of present data.

Usage : 

    $self->_filterColumnsByPercentPresentData($percent, $lineEnding, $numColumnsToReport);

=head2 _filterRowsOnColumnPercentile

NB: THIS METHOD HAS NOT YET BEEN IMPLEMENTED FOR BIG DATAMATRICES

This protected method filters out rows based on their column
percentile, when all data are known to be in memory, and optionally
allows for the percentiles of each datapoint to be displayed in the
output file.

Usage:

    $self->_filterRowsOnColumnPercentile($lineEnding, $numColumnsToReport, $percentile, $numColumns, $showPercentile);    

=head2 _filterRowsOnColumnDeviation

This protected method will filter out rows whose values do not deviate
from the column mean by a specified number of standard deviations, in
at least numColumns columns.

Usage:

    $self->_filterRowsOnColumnDeviation($lineEnding, $numRowsToReport, $deviations, $numColumns);

=head2 _filterRowsOnValues

This protected method filters out rows whose values do not pass a
specified criterion, in at least numColumns columns.

Usage : 

    $self->_filterRowsOnValues($value, $method, $lineEnding, $numRowsToReport, $numColumns);

=head2 _filterRowsOnVectorLength

This protected method filters out rows based on whether the vector
that their values define has a length of greater than the specified
length.

Usage :

    $self->_filterRowsOnVectorLength($requiredLength, $lineEnding, $numRowsToReport);

=head2 _logTransformData

This method log transforms the contents of the data matrix, using the
specified base for the log transformation.

Usage:

    $self->_logTransformData($logBase, $lineEnding, $numRowsToReport);

=head2 _scaleColumnData

This protected method scales the data for particular columns as
specified by the client, when all data are in memory.

Usage :

    $self->_scaleColumnData($columnsToFactorsHashRef, $lineEnding, $numColumnsToReport);

=head1 public methods

=head2 dumpData

This method dumps the current contents of the dataMatrix object to a
file, either whose name was provided as a single argument, or to a
file whose name was used to construct the object.

Usage:

    $self->dumpData($file);

=head1 AUTHOR

Gavin Sherlock

sherlock@genome.stanford.edu

=cut
