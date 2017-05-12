package Microarray::DataMatrix::SmallDataMatrix;

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
# Date   : 10th June 2002

# This package is intended to provide an abstraction layer to a
# dataMatrix whose size is such that all its contents, plus any
# additional data that will be generated during its processing, is
# small enough to fit into memory.  It is intended that
# smallDataMatrix will be subclassed by an anySizeDataMatrix object,
# which is what clients of smallDataMatrix will actually see.  It is
# up to the anySizeDataMatrix class itself to determine at runtime
# whether the matrix used for construction is small enough to be a
# smallDataMatrix.  Thus anySizeDataMatrix should have the details
# about how much memory is available, and a means of determing the
# size of the matrix being used for construction.  anySizeDataMatrix
# can then, at runtime, dynamically choose to inherit from
# smallDataMatrix, or the accompanying bigDataMatrix instead.

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

my $PACKAGE = 'Microarray::DataMatrix::SmallDataMatrix'; # will use to prefix all hash entries
                                             # which will prevent collision with
                                             # any attributes in super or sub
                                             # classes.

my $kMatrix      = $PACKAGE.'::__matrix';      # a pointer the in memory matrix
my $kPercentiles = $PACKAGE.'::__percentiles'; # a hash of the percentiles for the data, if they were requested


#####################################################################
sub _init{
#####################################################################
# This protected method will read in all the data for the matrix, and
# store it in memory.  It MUST be called during initialization of a
# subclass's object, before any other methods can be called.

    my ($self) = shift;

    $self->__readInAndStoreAllData;

}

#####################################################################
sub __readInAndStoreAllData{
#####################################################################
# This private method uses a concrete subclass's _dataLine method to
# request all data from the matrix, and read it into memory.
#
# Usage : $self->__readInAndStoreAllData;

    my $self = shift;
    
    my (@matrix, %validRows, %validColumns);
    
    my $rowNum = 0;
    
    # first we'll get all the data
    
    while (my $lineRef = $self->_dataLine($rowNum)){

	push (@matrix, $lineRef);

	$validRows{$rowNum} = undef; # record that this row is valid

	$rowNum++;

    }

    # now record the valid columns

    for (my $i = 0; $i < @{$matrix[0]}; $i++){

	$validColumns{$i} = undef; # record the valid columns

    }

    # now store the data in the object

    $self->_setValidColumns(\%validColumns);
    $self->_setValidRows(\%validRows);

    $self->__setMatrix(\@matrix);

}

#####################################################################
#
# PRIVATE SETTER METHODS - should only be used by this class
#
#####################################################################

#####################################################################
sub __setMatrix{
#####################################################################
# This private setter method receives a reference to an array of array
# references, (which contains the matrix itself), and stores it as a
# private attribute of the object.
#
# Usage: $self->__setMatrix(\@matrix);
#

    my ($self, $matrixArrayRef) = @_;
    
    $self->{$kMatrix} = $matrixArrayRef;
    
}

#####################################################################
sub __setPercentiles{
#####################################################################
# This private setter method receives a pointer to a hash of hashes
# that stores the percentiles of the data.  The first key in the hash
# is the row from which an element of data came, and the second is the
# column.  The value is the percentile for that piece of data in the
# column in which it is found.
#
# Usage : $self->__setPercentiles(\%percentiles);

    my ($self, $percentilesHashRef) = @_;
    
    $self->{$kPercentiles} = $percentilesHashRef;

}

######################################################################
sub __pareDownPercentiles{
######################################################################
# This private method deletes entries in the percentiles hash that are
# not needed - it's really just to save memory....
#
# Usage : $self->__pareDownPercentiles;

    my ($self) = @_;

    my $percentilesRef = $self->{$kPercentiles};

    my @invalidRows;

    foreach my $row (keys %{$percentilesRef}){

	push (@invalidRows, $row) if !$self->_matrixRowIsValid($row);

    }

    foreach my $row (@invalidRows){

	delete $percentilesRef->{$row};

    }

}

######################################################################
sub __invalidateMatrixRow{
######################################################################
# This private mutator method makes a row invalid.  We actually do the
# invalidation in the super class, but here, to save memory, we delete
# the data from the in memory matrix itself.  This method is not
# undoable, because the invalidation also deletes the data for the
# row.
#
# Usage : $self->__invalidateMatrixRow($row);

    my ($self, $row) = @_;

    $self->SUPER::_invalidateMatrixRow($row);

    undef $self->{$kMatrix}->[$row] if defined ($self->{$kMatrix}->[$row]); # eliminate data

}

#####################################################################
#
# PRIVATE GETTER METHODS - should only be used by this class
#
#####################################################################

######################################################################
sub __matrixArrayRef{
######################################################################
# This private method returns a reference to the 2-D array of data owned
# by the self object.
#
# usage : my $matrixArrayRef = $self->__matrixArrayRef;

    return $_[0]->{$kMatrix};

}

#
# ** DATA TRANSFORMATION METHODS
#

######################################################################
sub _centerColumns{
######################################################################
# This protected method centers each column of data, and returns the
# largest absolute value that was used in the centering.  The caller
# of the method must specify whether to center by means or medians.
#
# Usage :
#
#    $self->_centerColumns($centerColumnsMethod, $lineEnding, $numColumnsToReport);

    my ($self, $method, $lineEnding, $numColumnsToReport) = @_;

    my $largestVal = 0;
    
    defined $lineEnding && print ("Centering columns by $method", $lineEnding);
    
    my $num = 0;
    
    foreach my $column (@{$self->_validColumnsArrayRef}){
	
	if (defined $lineEnding && !($num++%$numColumnsToReport)){

	    print "Centering column $num", $lineEnding;
	    
	}
	
	my $average = $self->__columnAverage($column, $method) || next;
	
	$self->__centerColumn($column, $average);

	if (abs($average) > $largestVal){

	    $largestVal = abs($average);

	}

    }

    return $largestVal;
    
}

######################################################################
sub __columnAverage{
######################################################################
# This private method calculates and returns the average value for a
# column, depending on whether the mean or median was requested.
#
# Usage:
#
#    my $average = $self->__columnAverage($column, $method)

    my ($self, $column, $method) = @_;
    
    my $total = 0;
    my @data;
    my $numDatapoints = 0;    
    my $matrixArrayRef = $self->__matrixArrayRef;

    # simply examine the data for every row in the columm

    foreach my $row (@{$self->_validRowsArrayRef}){

	next if ($matrixArrayRef->[$row][$column] eq "");
	
	$total += $matrixArrayRef->[$row][$column]     if ($method eq "mean");
	push (@data, $matrixArrayRef->[$row][$column]) if ($method eq "median");
	$numDatapoints++;
	
    }
    
    return 0 if ($numDatapoints == 0); # may simply be a blank 'filler' column
    
    my $average = $self->_average($method, \@data, $total, $numDatapoints);
    
    return $average;

}

######################################################################
sub __centerColumn{
######################################################################
# This private method centers the data for a single column, by
# subtracting the average from every value.
#
# Usage :
#
#    $self->__centerColumn($column, $average);
#

    my ($self, $column, $average) = @_;
    
    my $matrixArrayRef = $self->__matrixArrayRef;
    
    foreach my $row (@{$self->_validRowsArrayRef}){
	
	next if ($matrixArrayRef->[$row][$column] eq "");	
	
	$matrixArrayRef->[$row][$column] -= $average;
	
    }
    
}

######################################################################
sub _centerRows{
######################################################################
# This protected method actually centers the row data, by calculating
# the average (mean or median, depending on what was requested) for
# each row, and then subtracting that value from each datapoint in the row.
#
# Usage :
#
#    $self->_centerRows($centerRowsMethod, $lineEnding, $numRowsToReport);
#

    my ($self, $method, $lineEnding, $numRowsToReport) = @_;
    
    my $matrixArrayRef = $self->__matrixArrayRef;
    
    defined $lineEnding && print ("Centering rows by $method", $lineEnding);
    
    my $num = 0;
    
    foreach my $row (@{$self->_validRowsArrayRef}){
	
	if (defined $lineEnding && !($num++%$numRowsToReport)){
	    
	    print "Centering row $num", $lineEnding;
	    
	}

	# next two methods are from superclass
	
	my $average = $self->_rowAverage($matrixArrayRef->[$row], $method) || next;

	$self->_centerRow($matrixArrayRef->[$row], $average);

    }

}

######################################################################
sub _filterRowsByPercentPresentData{
######################################################################
# This protected method invalidates rows that do not have greater than
# the requested percentage of present data
#
# Usage : 
#
# $self->_filterRowsByPercentPresentData($percent, $lineEnding, $numRowsToReport);
#

    my ($self, $percent, $lineEnding, $numRowsToReport) = @_;

    my $requiredNumDatapoints = $self->numColumns * ($percent / 100);
    
    my $matrixArrayRef = $self->__matrixArrayRef;
    
    my $num = 0;
    
    foreach my $row (@{$self->_validRowsArrayRef}){
	
	if (defined $lineEnding && !($num++%$numRowsToReport)){
	    
	    print "Filtering row $num", $lineEnding;
	    
	}
	
	my $numDatapoints = 0;
	
	foreach my $column (@{$self->_validColumnsArrayRef}){
	    
	    next if ($matrixArrayRef->[$row][$column] eq "");
	    
	    $numDatapoints++;
	    
	}
	
	$self->__invalidateMatrixRow($row) unless ($numDatapoints > $requiredNumDatapoints);
	
    }
    
}


######################################################################
sub _filterColumnsByPercentPresentData{
######################################################################
# This protected method invalidates columns that do not have greater
# than the requested percentage of present data
#
# Usage : $self->_filterColumnsByPercentPresentData($percent, $lineEnding, $numColumnsToReport);
    
    my ($self, $percent, $lineEnding, $numColumnsToReport) = @_;
    
    my $requiredNumDatapoints = $self->numRows * ($percent / 100);
    
    my $matrixArrayRef = $self->__matrixArrayRef;
    
    my $num = 0;
    
    foreach my $column (@{$self->_validColumnsArrayRef}){
	
	if (defined $lineEnding && !($num++%$numColumnsToReport)){
	    
	    print "Filtering column $num", $lineEnding;
	    
	}
	
	my $numDatapoints = 0;
	
	foreach my $row (@{$self->_validRowsArrayRef}){

	    next if ($matrixArrayRef->[$row][$column] eq "");

	    $numDatapoints++;

	}

	$self->_invalidateMatrixColumn($column) unless ($numDatapoints > $requiredNumDatapoints);

    }	    

}

#####################################################################
sub _filterRowsOnColumnPercentile{
#####################################################################
# This protected method filters out rows based on their column
# percentile, when all data are known to be in memory, and optionally
# allows for the percentiles of each datapoint to be displayed in the
# output file.
#
# Usage:
#
# $self->_filterRowsOnColumnPercentile($lineEnding, $numColumnsToReport, $percentile, $numColumns, $showPercentile);
#

    my ($self, $lineEnding, $numColumnsToReport, $percentile, $numColumns, $showPercentile) = @_;

    my $matrixArrayRef = $self->__matrixArrayRef;

    my (%count, %percentiles, %rowToValue);

    my $num = 0;

    # go through every column

    foreach my $column (@{$self->_validColumnsArrayRef}){

	if (defined $lineEnding && !($num++%$numColumnsToReport)){

	    print "Examining percentiles of column $num", $lineEnding;

	}

	%rowToValue = ();

	foreach my $row (@{$self->_validRowsArrayRef}){

	    next if ($matrixArrayRef->[$row][$column] eq "");

	    $rowToValue{$row} = $matrixArrayRef->[$row][$column]; # build hash

	}

	# sort the row_no's in order of values

	my @rowsInValueOrder = sort {$rowToValue{$a} <=> $rowToValue{$b}} keys %rowToValue;

	my $minIndex = int(@rowsInValueOrder * ($percentile/100));
	
	for (my $index = $minIndex; $index < @rowsInValueOrder; $index++){

	    $count{$rowsInValueOrder[$index]}++; # count only those in the correct percentile

	}

	if ($showPercentile){ # they want the percentile in the output

	    # we need to store the percentiles of every row for every column

	    foreach (my $index = 0; $index < @rowsInValueOrder; $index++){

		$percentiles{$rowsInValueOrder[$index]}{$column} = sprintf "%.4f", $index/@rowsInValueOrder;

	    }

	}

    }

    # now invalidate all rows, which don't have a high enough count
    # across columns

    $self->__filterRowsByCount(\%count, $numColumns);
    
    # now weed out the percentiles hash to only store those we need

    if ($showPercentile) { # now store the requested percentiles

	$self->__setPercentiles(\%percentiles);
	$self->__pareDownPercentiles;

    }

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
# Usage:
#
# $self->__filterRowsByCount(\%count, $numColumns);

    my ($self, $rowToCountHashRef, $threshold) = @_;

    foreach my $row (@{$self->_validRowsArrayRef}){

	if (!exists($rowToCountHashRef->{$row}) || $rowToCountHashRef->{$row} < $threshold){

	    $self->__invalidateMatrixRow($row);

	}

    }

}

########################################################################
sub _filterRowsOnColumnDeviation{
########################################################################
# This protected method will filter out rows whose values do not
# deviate from the column mean by a specified number of standard
# deviations, in at least numColumns columns.
#
# Usage:
#
# $self->_filterRowsOnColumnDeviation($lineEnding, $numRowsToReport, $deviations, $numColumns);

    my ($self, $lineEnding, $numRowsToReport, $deviations, $numColumns) = @_;
    
    # first need to get the standard deviations of all valid columns
    
    my ($stddevHashRef, $meansHashRef) = $self->__validColumnsStdDevAndMeanHashRefs($lineEnding);
    
    # now calculate the upper and lower bounds for each column

    my ($upperHashRef, $lowerHashRef) = $self->_calculateBounds($stddevHashRef, $meansHashRef, $deviations, $lineEnding);

    # now count up how many values in each row lie outside of the
    # specified number of deviations from the mean, for each row    

    defined $lineEnding && print("Running filters over each row", $lineEnding);
    
    my $num = 0;

    my (%count, $val);

    my $matrixArrayRef = $self->__matrixArrayRef;
    
    # go through every row
    
    foreach my $row (@{$self->_validRowsArrayRef}){
	
	if (defined $lineEnding && !($num++%$numRowsToReport)){
	    
	    print "Filtering row $num", $lineEnding;
	    
	}
	
	foreach my $column (@{$self->_validColumnsArrayRef}){

	    $val = $matrixArrayRef->[$row][$column];
	    
	    next if ($val eq "");
	    
	    next unless ($val > $upperHashRef->{$column} || $val < $lowerHashRef->{$column});

	    $count{$row}++; # this value passes the criteria

	}

    }

    $self->__filterRowsByCount(\%count, $numColumns);

}

######################################################################
sub __validColumnsStdDevAndMeanHashRefs{
######################################################################
# This private method calculates the standard deviations for each
# valid column, and returns references to two hashes.  Both have the
# column index as the key, and one has the standard deviation as the
# values, the other has the column means as the values.
#
# mean = Sum of values/n
# std dev = square root (((n * sum of (x^2)) - (sum of x)^2)/n(n-1))

    my ($self, $lineEnding) = @_;

    my $matrixArrayRef = $self->__matrixArrayRef;

    my (%sumOfX, %sumX2, %numDataPoints, $val);

    defined $lineEnding && print ("Calculating mean and standard deviations for each column", $lineEnding);

    foreach my $row (@{$self->_validRowsArrayRef}){

	foreach my $column (@{$self->_validColumnsArrayRef}){

	    $val = $matrixArrayRef->[$row][$column];

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
# This protected method filters out rows whose values do not pass a
# specified criterion, in at least numColumns columns.
#
# Usage : $self->_filterRowsOnValues($value, $method, $lineEnding, $numRowsToReport, $numColumns);
#

    my ($self, $value, $method, $lineEnding, $numRowsToReport, $numColumns) = @_;
    
    my $matrixArrayRef = $self->__matrixArrayRef;
    
    my (%count, $datum);
    
    my $num = 0;
    
    foreach my $row (@{$self->_validRowsArrayRef}){
	
	if (defined $lineEnding && !($num++%$numRowsToReport)){
	    
	    print "Filtering row $num", $lineEnding;
	    
	}
	
	foreach my $column (@{$self->_validColumnsArrayRef}){
	    
	    $datum = $matrixArrayRef->[$row][$column];

	    next if $datum eq "";

	    # following method call returns true if value passes criteria

	    $count{$row}++ if ($self->$method($datum, $value));

	}
	
    }

    $self->__filterRowsByCount(\%count, $numColumns);

}

######################################################################
sub _filterRowsOnVectorLength{
######################################################################
# This protected method filters out rows based on whether the vector
# that their values define has a length of greater than the specified
# length.
#
# Usage :
#
# $self->_filterRowsOnVectorLength($requiredLength, $lineEnding, $numRowsToReport); 

    my ($self, $requiredLength, $lineEnding, $numRowsToReport) = @_;

    my $matrixArrayRef = $self->__matrixArrayRef;

    my $val;

    my $num = 0;

    foreach my $row (@{$self->_validRowsArrayRef}){

	if (defined $lineEnding && !($num++%$numRowsToReport)){

	    print "Filtering row $num", $lineEnding;

	}

	my $sumSquares;

	foreach my $column (@{$self->_validColumnsArrayRef}){
    
	    $val = $matrixArrayRef->[$row][$column];

	    next if $val eq "";

	    $sumSquares += $val**2;

	}

	# invalidate those who don't pass the length requirement

	$self->__invalidateMatrixRow($row) unless sqrt($sumSquares) > $requiredLength;
	
    }
    
}

######################################################################
sub _logTransformData{
######################################################################
# This method log transforms the contents of the data matrix, using
# the specified base for the log transformation.  
# 
# Usage:
#
# $self->_logTransformData($logBase, $lineEnding, $numRowsToReport);

    my ($self, $logBase, $lineEnding, $numRowsToReport) = @_;

    $self->__dieIfNegativeDataExistInMatrix;

    my ($val, $column, $row);

    my $matrixArrayRef = $self->__matrixArrayRef;    

    my $num = 0;

    foreach $row (@{$self->_validRowsArrayRef}){

	if (defined $lineEnding && !($num++%$numRowsToReport)){

	    print "Log transforming row $num", $lineEnding;

	}

	foreach $column (@{$self->_validColumnsArrayRef}){

	    $val = $matrixArrayRef->[$row][$column];

	    next if (!defined $val || $val eq ""); # skip blanks

	    $matrixArrayRef->[$row][$column] = sprintf "%.4f", log($val)/$logBase;

	}

    }

}

######################################################################
sub __dieIfNegativeDataExistInMatrix{
######################################################################
# This private function dies, with an appropriate error message, if any
# negative data value is found within the matrix.
#
# Usage : $self->__dieIfNegativeDataExistInMatrix;

    my ($self) = @_;

    my $matrixArrayRef = $self->__matrixArrayRef;

    my ($val, $row, $column);

    foreach $column (@{$self->_validColumnsArrayRef}){

	foreach $row (@{$self->_validRowsArrayRef}){

	    $val = $matrixArrayRef->[$row][$column];
	    
	    next if (!defined $val || $val eq ""); # skip blanks
	    
	    if ($val <= 0){
		
		die "The data could not be transformed : the negative value $val exists in row $row, column $column";
		
	    }
	    
	}
	
    }
    
}

######################################################################
sub _scaleColumnData{
######################################################################
# This protected method scales the data for particular columns as
# specified by the client, when all data are in memory.
#
# Usage :
#
# $self->_scaleColumnData($columnsToFactorsHashRef, $lineEnding, $numColumnsToReport);
#
    my ($self, $columnsToFactorsHashRef, $lineEnding, $numColumnsToReport) = @_;

    my $matrixArrayRef = $self->__matrixArrayRef;

    my $num = 0;

    my ($val, $scalingFactor);

    foreach my $column (keys %{$columnsToFactorsHashRef}){

	if (!$self->_matrixColumnIsValid($column)){

	    print STDERR "The column index, $column, is not valid for this dataMatrix.\n";
	    next;

	}

	$scalingFactor = $columnsToFactorsHashRef->{$column};

	if (!defined $scalingFactor || $scalingFactor == 0){

	    print STDERR "The scaling factor supplied for $column was \"$scalingFactor\".\n";
	    print STDERR "It will not be used.\n";

	    next;

	}

	if (defined $lineEnding && !($num++%$numColumnsToReport)){

	    print "Scaling data for column $num with scaling factor $scalingFactor", $lineEnding;

	}
	
	foreach my $row (@{$self->_validRowsArrayRef}){
	    
	    $val = $matrixArrayRef->[$row][$column];

	    next if $val eq ""; # skip blanks

	    $matrixArrayRef->[$row][$column] =  sprintf "%.4f", $val/$scalingFactor;

	}

    }

}

###################################################################################
sub dumpData{
###################################################################################
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

    $file ||= $self->file;
    
    # have to think about this bit....

    my $hasPercentiles = exists $self->{$kPercentiles};

    my $percentilesRef = $self->{$kPercentiles};
    
    open (DATAOUT, ">$file") || die "Cannot open $file for writing : $!.\n";

    # print first line

    $self->_printLeadingMeta(\*DATAOUT, $self->_validColumnsArrayRef, $hasPercentiles, "percentile");

    my $matrixArrayRef   = $self->__matrixArrayRef;
    
    # now go through each valid row
    
    foreach my $row (sort {$a <=> $b } @{$self->_validRowsArrayRef}){
	
	$self->_printRow(\*DATAOUT, $row, $matrixArrayRef->[$row], $self->_validColumnsArrayRef, $hasPercentiles, $percentilesRef);
	
    }
    
    $self->_printTrailingMeta(\*DATAOUT, $self->_validColumnsArrayRef, $hasPercentiles);
    
    close DATAOUT;


}

1; # to keep Perl happy

=pod

=head1 NAME

Microarray::DataMatrix::SmallDataMatrix - abstraction to matrices that fit in memory

=head1 Abstract

smallDataMatrix is an abstract class, which provides as abstraction to
an in memory matrix of data.  It should not be subclassed by concrete
subclasses.  Instead, the subclass anySizeDataMatrix, can be
subclassed with concrete subclasses, which will provide abstractions
to dataMatrices stored in particular file formats, such as pcl files.

=head1 Overall Logic

Internally, all data are read into memory, and the actual data matrix
is stored as a 2 dimensional array.  The indexes of the array which
are still valid are stored in internal hashes, such that subsequent
manipulations of the data only consider the data that have not been
filtered out.  As rows or columns are filtered out by some of the
methods, the entries for these rows or columns are deleted from the
hashes that track valid data.  Thus when data are redumped to a file,
only those data that have not been filtered are printed out.

=head1 Construction

As smallDataMatrix is an abstract class, it has no constructor.
However, the subclass, anySizeDataMatrix, once it has determined that
a matrix will indeed fit into memory, MUST call the _init method,
which will result in all data being read into memory.

=head2 _init

This protected method will read in all the data for the matrix, and
store it in memory.  It MUST be called during initialization of a
subclass object, before any other methods can be called by the client.

Usage:

    $self->_init;

or:

    $self->SUPER::_init;

=head1 private utility methods

=head2 __readInAndStoreAllData

This private method uses the _dataLine method from a concrete subclass
to request all data from the matrix, and read it into memory, then
store it internally.

Usage : 

    $self->__readInAndStoreAllData;

=head2 __columnAverage

This private method calculates and returns the average value for a
column, depending on whether the mean or median was requested.

Usage:

    my $average = $self->__columnAverage($column, 'mean');

=head2 __centerColumn

This private method centers the data for a single column, by
subtracting the average from every valid value.

Usage :

    $self->__centerColumn($column, $average);

=head2 __filterRowsByCount

This private method filters out rows that do not have a count for some
particular property above or equal to a threshold.  It accepts a hash
reference, that hashes the row number to a count, and a threshold
value.  Note that not all rows are necessarily entered into the hash,
so this method iterates over all rows, and checks each valid one for
its count in the hash, then invalidates those with too low a count.

Usage:

    $self->__filterRowsByCount(\%count, $numColumns);

=head2 __validColumnsStdDevAndMeanHashRefs

This private method calculates the standard deviations for each valid
column, and returns references to two hashes.  Both have the column
index as the key, and one has the standard deviation as the values,
the other has the column means as the values.

    mean = Sum of values/n
    std dev = square root (((n * sum of (x^2)) - (sum of x)^2)/n(n-1))

Usage:

    my ($stddevHashRef, $meansHashRef) = $self->__validColumnsStdDevAndMeanHashRefs($lineEnding);

=head2 __dieIfNegativeDataExistInMatrix

This private function dies, with an appropriate error message, if any
negative data value is found within the matrix.

Usage:

    $self->__dieIfNegativeDataExistInMatrix;

=head1 private setter methods

=head2 __setMatrix

This private setter method receives a reference to an array of array
references (which contains the matrix itself), and stores it as a
private attribute of the object.

Usage : 

    $self->__setMatrix(\@matrix);

=head2 __setPercentiles

This private setter method receives a pointer to a hash of hashes that
stores the percentiles of the data.  The first key in the hash is the
row from which an element of data came, and the second is the column.
The value is the percentile for that piece of data in the column in
which it is found.

Usage : 

    $self->__setPercentiles(\%percentiles);

=head2 __pareDownPercentiles

This private method deletes entries in the percentiles hash that are
not needed - it is really just to save memory....

Usage : 

    $self->__pareDownPercentiles;

=head2 __invalidateMatrixRow

This private mutator method makes a row invalid.  The invalidation is
actually done by the the super class, but here, to save memory, we
delete the data from the in memory matrix itself.  This method is not
undoable, because the invalidation also deletes the data for the row.

Usage : 

    $self->__invalidateMatrixRow($row);

=head1 private getter methods

=head2 __matrixArrayRef

This private method returns a reference to the 2-D array of data owned
by the self object.

Usage : 

    my $matrixArrayRef = $self->__matrixArrayRef;

=head1 Protected data transformation/filtering methods

Note: These methods provide the backend nuts and bolts for a
transformation or filtering.  They should only be called by the
immediate subclass, anySizeDataMatrix, and not directly by the
concrete subclasses of anySizeDataMatrix.  In addition, note that the
companion bigDataMatrix must (and does) provide identical interfaces
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
the average (mean or median, depending on what was requested) for each
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
