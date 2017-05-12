package Microarray::DataMatrix;

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
# Date   : 11th June 2002

# This package provides a base class for dealing with the contents
# of a dataMatrix, providing a structure whereby tracking of whether
# rows or columns in the matrix are deemed valid, and some primitives
# are provided for manipulating the data.

use strict;

####################################################################
#
# CLASS GLOBALS
#
####################################################################

# The following globals are used so we only ever access hash entries
# (ie object attributes) using variables, to prevent typos, or
# accidental clobberring.

# These values are assigned here and then are READ-ONLY.

my $PACKAGE = ' Microarray::DataMatrix';     # will use to prefix all hash entries
                                # which will prevent collision with
                                # any attributes in super or sub
                                # classes.

my $kValidColumns       = $PACKAGE.'::__validColumns';       # the currently valid columns
my $kValidRows          = $PACKAGE.'::__validRows';          # the currently valid rows
my $kErrstr             = $PACKAGE.'::__errstr';             # to hold the contents of the last error
my $kNumColumnsToReport = $PACKAGE.'::__numColumnsToReport'; # for when someone wants verbose reporting
my $kNumRowsToReport    = $PACKAGE.'::__numRowsToReport';    # for when someone wants verbose reporting
my $kAutoDump           = $PACKAGE.'::__autoDump';           # whether to autodump

my $kNumberFormat = "%.3f";  # precision for average, etc.

my %kLineEndings = (text=>"\n",
		    html=>"\n<br>");

my %kAllowedCenteringMethods = ('mean'   => undef,
				'median' => undef);

# The following hash contains the names of all the operators, and
# their aliases, that a client can use when filtering rows based on
# the actual data.  The values are the names of methods that are used to
# do the comparison.  Each  method simply takes two values, one being the
# left hand value, and one the right hand value of the comparison.

my %kAllowedOperators = ("absolute value >"  => "_absgt",
			 "absolute value >=" => "_absgteq",
			 "absolute value ="  => "_abseq",
			 "absolute value <"  => "_abslt",
			 "absolute value <=" => "_abslteq",
			 ">"                 => "_gt",
			 ">="                => "_gteq",
			 "="                 => "_eq",
			 "<="                => "_lteq",
			 "<"                 => "_lt",
			 "not equal"         => "_ne",
			 "absgt"             => "_absgt",
			 "absgteq"           => "_absgteq",
			 "abseq"             => "_abseq",
			 "abslt"             => "_abslt",
			 "abslteq"           => "_abslteq",
			 "gt"                => "_gt",
			 "gteq"              => "_gteq",
			 "eq"                => "_eq",
			 "lteq"              => "_lteq",
			 "lt"                => "_lt",
			 "ne"                => "_ne",
			 "|>|"               => "_absgt",
			 "|>=|"              => "_absgteq",
			 "|=|"               => "_abseq",
			 "|<|"               => "_abslt",
			 "|<=|"              => "_abslteq",
			 "=="                => "_eq",
			 "!="                => "_ne");

#####################################################################
#
# PROTECTED SETTER METHODS - should only be used by subclasses
#
#####################################################################

#####################################################################
sub _setAutoDump{
#####################################################################
# This method is used to set the autodump flag, which can be either 1
# or 0.  This should only be utilized by subclasses, not clients.
#
# Usage: $self->_setAutoDump(1);

    my ($self, $value) = @_;

    if ($value != 0 && $value != 1){

	$self->_usage("setAutoDump requires an argument of either 0 or 1!\nYou provided : \"$value\"\n");

    }

    $self->{$kAutoDump} = $value;

}

#####################################################################
sub _setValidColumns{
#####################################################################
# This protected setter method receives a reference to a hash, which
# has as its keys the index of the columns which are valid.  This
# method is expected to only be used when the matrix has been first
# read, to set up all the columns which are initially valid.  The
# values of the hash will usually be undef, to simply save space.
# There is no expectation for them to be otherwise.
#
# Usage: $self->_setValidColumns(\%validColumns);
#

    my ($self, $validColumnsHashRef) = @_;
    
    $self->{$kValidColumns} = $validColumnsHashRef;
    
}
 
#####################################################################
sub _setValidRows{
#####################################################################
# This protected setter method receives a reference to a hash, which
# has as its keys the index of the rows which are valid.  This
# method is expected to only be used when the matrix has been first
# read, to set up all the rows which are initially valid.  The
# values of the hash will usually be undef, to simply save space.
# There is no expectation for them to be otherwise.
#
# Usage: $self->_setValidRows(\%validRows);
#

    my ($self, $validRowsHashRef) = @_;
    
    $self->{$kValidRows} = $validRowsHashRef;
    
}

#####################################################################
sub _setErrstr{
#####################################################################
# This protected setter method accepts a scalar, that will correspond
# to an error that has occurred, and will store it within the object.
#
# Usage: $self->_setErrstr($error);

    my ($self, $errstr) = @_;

    $self->{$kErrstr} = $errstr;

}

######################################################################
sub _invalidateMatrixRow{
######################################################################
# This protected mutator method makes a row invalid.  This method is not
# undoable, because the invalidation also deletes the data for the row.
#
# Usage : $self->_invalidateMatrixRow($row);

    my ($self, $row) = @_;

    delete $self->{$kValidRows}->{$row}; # make invalid

}

######################################################################
sub _invalidateMatrixColumn{
######################################################################
# This protected mutator method makes a column invalid.
#
# Usage : $self->_invalidateMatrixColumn($column);

    my ($self, $column) = @_;
    
    delete $self->{$kValidColumns}->{$column}; # make invalid

}

#####################################################################
#
# PROTECTED GETTER/ACCESSOR METHODS - should only be used by this
# class, and subclasses
#
#####################################################################

#####################################################################
sub _autoDump{
#####################################################################
# This protected method returns a boolean to indicate whether
# autodumping is enabled.
#
# Usage : if ($self->_autoDump){ # blah };

    return $_[0]->{$kAutoDump};

}

######################################################################
sub _validRowsArrayRef{
######################################################################
# This protected accessor returns a reference to an array that contains
# the indexes of all the valid rows
#
# Usage:
#
# foreach my $row (@{$self->_validRowsArrayRef}){
#
#        # do something useful
#
# }

    return [keys %{$_[0]->{$kValidRows}}];

}

######################################################################
sub _validColumnsArrayRef{
######################################################################
# This protected accessor returns a reference to an array that contains
# the indexes of all the valid columns.
#
# Usage:
#
# foreach my $column (@{$self->_validColumnsArrayRef}){
#
#        # do something useful
#
# }

    return [keys %{$_[0]->{$kValidColumns}}];

}

######################################################################
sub _matrixRowIsValid{
######################################################################
# This protected accessor returns a boolean to indicate whether a
# given row in the data matrix is still valid (ie has not been
# filtered out)
#
# Usage : if ($self->_matrixRowIsValid($row)){ # blah }

    return exists $_[0]->{$kValidRows}->{$_[1]};

}

######################################################################
sub _matrixColumnIsValid{
######################################################################
# This protected accessor returns a boolean to indicate whether a
# given column in the data matrix is still valid (ie has not been
# filtered out)
#
# Usage : if ($self->_matrixColumnIsValid($column)){ # blah }

    return exists $_[0]->{$kValidColumns}->{$_[1]};

}

#####################################################################
sub _numColumnsToReport{
#####################################################################
# This protected method returns the number of columns to process after which
# reporting should be done, if verbose reporting has been indicated.
# If no value has been set, then the default of 50 is returned.
#
# Usage :
#
# my $numColumnsToReport = $self->_numColumnsToReport;
#

    my ($self) = @_;

    if (!exists $self->{$kNumColumnsToReport}){

	$self->setNumColumnsToReport(50); # set to default

    }

    return $self->{$kNumColumnsToReport};

}

#####################################################################
sub _numRowsToReport{
#####################################################################
# This protected method returns the number of rows to process after which
# reporting should be done, if verbose reporting has been indicated.
# If no value has been set, then the default of 5000 is returned.
#
# Usage :
#
# my $numRowsToReport = $self->_numRowsToReport;
#

    my ($self) = @_;

    if (!exists $self->{$kNumRowsToReport}){

	$self->setNumRowsToReport(5000);

    }

    return $self->{$kNumRowsToReport};

}

#####################################################################
sub _lineEnding{
#####################################################################
# This protected method returns the appropriate line ending, for text
# or html reporting.  It expects a string, either 'html' or 'text' and
# will return the appropriate line ending.
#
# Usage:
#
# my $lineEnding = $self->_lineEnding("text");

    my ($self, $reportingType) = @_;

    if (exists $kLineEndings{lc($reportingType)}){

	return $kLineEndings{lc($reportingType)};

    }else{

	die "The reporting type '$reportingType' is not recognized.";

    }

}

#####################################################################
sub _centeringMethodIsAllowed{
#####################################################################
# This protected method returns a boolean to indicate whether a
# centering method is allowed.  Allowed methods are 'mean' and
# 'median'.
#
# Usage : if ($self->_centeringMethodIsAllowed($method)){ # blah }

    my ($self, $method) = @_;

    return exists $kAllowedCenteringMethods{$method};

}

#####################################################################
sub _operatorIsAllowed{
#####################################################################
# This protected method returns a boolean to indicate whether a
# particular operator is allowed.  For each operator, there exists a
# corresponding method that uses that operator.

#
# Usage : if ($self->_operatorIsAllowed($operator)){ # blah }

    my ($self, $operator) = @_;

    return exists $kAllowedOperators{$operator};

}

######################################################################
sub _methodForOperator{
######################################################################
# This protected method returns the name of the method that is used to compare
# two values, based on the operator that was passed in.
#
# Usage : my $method = $self->_methodForOperator($operator);
#

    my ($self, $operator) = @_;

    return $kAllowedOperators{$operator};

}

# The following set of protected methods are used for comparing two
# values to each other.  All of them return a boolean to indicate if
# the comparison failed or succeeded

######################################################################
sub _absgt{
######################################################################
# This method returns a boolean to indicate if the first argument is
# absolutely greater than the second argument.
#
# Usage: if ($self->_absgt($x, $y)){ # blah }

    my ($self, $lhs, $rhs) = @_;

    return (abs($lhs) > abs($rhs));

}

######################################################################
sub _absgteq{
######################################################################
# This method returns a boolean to indicate if the first argument is
# absolutely greater than or equal to the second argument.
#
# Usage: if ($self->_absgteq($x, $y)){ # blah }

    my ($self, $lhs, $rhs) = @_;

    return (abs($lhs) >= abs($rhs)); 

}

######################################################################
sub _abseq{
######################################################################
# This method returns a boolean to indicate if the first argument is
# absolutely equal to the second argument.
#
# Usage: if ($self->_abseq($x, $y)){ # blah } 

    my ($self, $lhs, $rhs) = @_;
    
    return (abs($lhs) == abs($rhs));

}

######################################################################
sub _abslt{
######################################################################
# This method returns a boolean to indicate if the first argument is
# absolutely less than the second argument.
#
# Usage: if ($self->_abslt($x, $y)){ # blah } 

    my ($self, $lhs, $rhs) = @_;

    return (abs($lhs) < abs($rhs));

}

######################################################################
sub _abslteq{
######################################################################
# This method returns a boolean to indicate if the first argument is
# absolutely less than or equal to the second argument.
#
# Usage: if ($self->_abslteq($x, $y)){ # blah } 

    my ($self, $lhs, $rhs) = @_;
    
    return (abs($lhs) <= abs($rhs));

}

######################################################################
sub _gt{
######################################################################
# This method returns a boolean to indicate if the first argument is
# greater than the second argument.
#
# Usage: if ($self->_gt($x, $y)){ # blah } 

    my ($self, $lhs, $rhs) = @_;

    return ($lhs > $rhs);

}

######################################################################
sub _gteq{
######################################################################
# This method returns a boolean to indicate if the first argument is
# greater than or equal to the second argument.
#
# Usage: if ($self->_gteq($x, $y)){ # blah } 

    my ($self, $lhs, $rhs) = @_;

    return ($lhs >= $rhs);

}

######################################################################
sub _eq{
######################################################################
# This method returns a boolean to indicate if the first argument is
# equal to the second argument.
#
# Usage: if ($self->_eq($x, $y)){ # blah } 

    my ($self, $lhs, $rhs) = @_;
    
    return ($lhs == $rhs)

}

######################################################################
sub _lteq{
######################################################################
# This method returns a boolean to indicate if the first argument is
# less than or equal to the second argument.
#
# Usage: if ($self->_lteq($x, $y)){ # blah } 

    my ($self, $lhs, $rhs) = @_;

    return ($lhs <= $rhs);

}

######################################################################
sub _lt{
######################################################################
# This method returns a boolean to indicate if the first argument is
# less than the second argument.
#
# Usage: if ($self->_lt($x, $y)){ # blah } 

    my ($self, $lhs, $rhs) = @_;

    return ($lhs < $rhs);

}

######################################################################
sub _ne{
######################################################################
# This method returns a boolean to indicate if the first argument is
# not equal to the second argument.
#
# Usage: if ($self->_ne($x, $y)){ # blah } 

    my ($self, $lhs, $rhs) = @_;
    
    return ($lhs != $rhs);

}

# Utility methods

######################################################################
sub _rowAverage{
######################################################################
# This method returns the average of the valid entries in the row,
# using either the mean or the median, depending on the requested
# method.  The row is passed in a reference to an array containing the
# values for the row.  If no mean/median could be calculated, then the
# method returns undef.

    my ($self, $rowRef, $method) = @_;
    
    my $total = 0;
    my @data;
    my $numDatapoints = 0;
    
    foreach my $column (@{$self->_validColumnsArrayRef}){
	
	next if ($rowRef->[$column] eq "");
	
	$total += $rowRef->[$column]     if ($method eq "mean");
	push (@data, $rowRef->[$column]) if ($method eq "median");
	$numDatapoints++;
	
    }
    
    return undef if ($numDatapoints == 0); # could just be a spacer row in the matrix
    
    return $self->_average($method, \@data, $total, $numDatapoints);    
    
}

######################################################################
sub _average{
######################################################################
# This method calculates the average of a set of data, by receiving
# the total number of datapoints, and either an array by reference of
# all the datavalues, or the sum total of all the datapoints.  The
# former is required to calculate the median (and is not assumed to be
# sorted), the latter to calculate the mean.  The method must also be
# passed in.  The number of datapoints must be non-zero

    my ($self, $method, $dataRef, $total, $numDatapoints) = @_;

    my $average;

    if ($method eq "mean"){
	
	$average = $total/$numDatapoints;
	
    }elsif ($method eq "median"){
	
	$numDatapoints = scalar @{$dataRef};

	@{$dataRef} = sort {$a <=> $b} @{$dataRef};
	
	if (!($numDatapoints%2)){ # even  number of entries
	    $average = ($dataRef->[$numDatapoints/2] + $dataRef->[($numDatapoints/2)-1]) / 2;
	}else{ # odd number of entries
	    $average = $dataRef->[int($numDatapoints/2)];
	}
	
    }

    return sprintf($kNumberFormat, $average);

}

######################################################################
sub _centerRow{
######################################################################
# This protected method takes an array reference to a row, and the
# average (either mean or median, depending on what was requested),
# and subtracts that value from every valid value in the row

    my ($self, $rowRef, $average) = @_;

    foreach my $column (@{$self->_validColumnsArrayRef}){
	    
	next if ($rowRef->[$column] eq "");

	$rowRef->[$column] -= $average;

    }

}

######################################################################
sub _calculateMeansAndStdDeviations{
######################################################################
# This method expects to receive hashes of the sums of X, the sums of
# X squared and the number of datapoints, where the keys for each hash
# are the unique identifiers for a series of numbers, whose mean and
# standard deviations are to be calculated.  It returns references to
# hashes that hash the same id's to the means and standard deviations.
# It uses the n-1 version of standard deviation.  If no standard deviation
# can be calculated, then it will be designated as undef.
    
    my ($self, $sumOfXHashRef, $sumX2HashRef, $numDataPointsHashRef) = @_;
    
    my (%means, %deviations, $n);
    
    foreach my $column (keys %{$numDataPointsHashRef}){
	
	$n = $numDataPointsHashRef->{$column};
	
	$means{$column}      = $sumOfXHashRef->{$column}/$n;

	if ($n >= 2){

	    $deviations{$column} = sqrt(($n * $sumX2HashRef->{$column} - $sumOfXHashRef->{$column}**2)/($n*($n-1)));
	
	}else{

	    $deviations{$column} = undef;

	}

    }
    
    return (\%deviations, \%means);
    
}

######################################################################
sub _calculateBounds{
######################################################################
# This method receives two hashes by reference.  One is a hash of
# means, the other a hash of std deviations.  It also receives a
# multiplier.  It then calculates, and returns as hash references, the
# upper and lower bounds for the mean plus or minus that number of
# deviations

    my ($self, $stddevHashRef, $meansHashRef, $deviations, $lineEnding) = @_;

    my (%upper, %lower, $val);

    defined $lineEnding && print("Calculating upper and lower bounds for filter.", $lineEnding);

    foreach my $column (keys %{$meansHashRef}){

	die "A standard deviation for column $column could not be calculated.\n" if (!defined($stddevHashRef->{$column}));

	$val = $stddevHashRef->{$column} * $deviations;

	$upper{$column} = $meansHashRef->{$column} + $val;
	$lower{$column} = $meansHashRef->{$column} - $val;

    }

    return (\%upper, \%lower);

}

#####################################################################
sub _giveOverrideMessage{
#####################################################################
# This protected utility method can be used by any subclass that
# expects its own subclasses to implement certain methods.  It can
# have stub methods, that simply call this method, which will give a
# standard error message saying that the class 'X' must override
# method Y.

    my ($self) = shift;

    my $class = ref $self;

    my $caller = (caller(1))[3];

    my $message =  "The method, $caller, was invoked on a $class object.\n";
    $message   .= "That method must be implemented in the $class package.\n";
    $message   .= "\n\nA full stack trace is below:\n\n";

    confess ($message);

}

#####################################################################
#
# PUBLIC SETTER METHODS - can be used by anyone
#
#####################################################################

#####################################################################
sub setNumColumnsToReport{
#####################################################################
# This methods accepts an integer, that indicates the number of
# columns after which progress should be indicated, during a
# transformation that involves column processing.
#
# Usage : $matrix->setNumColumnsToReport(50);
#

    my ($self, $num) = @_;

    if ($num < 1 || $num != int($num)){

	die "setNumColumnsToReport must be given an integer greater than or equal to 1.";

    }

    $self->{$kNumColumnsToReport} = $num;

}

#####################################################################
sub setNumRowsToReport{
#####################################################################
# This methods accepts an integer, that indicates the number of
# rows after which progress should be indicated, during a
# transformation that involves row processing.
#
# Usage : $matrix->setNumRowsToReport(50);
#

    my ($self, $num) = @_;

    if ($num < 1 || $num != int($num)){

	die "setNumRowsToReport must be given an integer greater than or equal to 1.";

    }

    $self->{$kNumRowsToReport} = $num;

}

#####################################################################
#
# PUBLIC GETTER/ACCESSOR METHODS - can be used by anyone
#
#####################################################################

######################################################################
sub numRows{
######################################################################
# This public method returns the number of valid rows that are in the
# dataMatrix.  Subclasses MUST determine the number of rows in the matrix
# prior to allowing methods to be called on the object.
#
# Usage : my $numRows = $dataMatrix->numRows;

    return scalar @{$_[0]->_validRowsArrayRef};

}

#######################################################################
sub numColumns{
#######################################################################
# This public method returns the number of valid columns that are in the 
# dataMatrix.  Concrete subclasses must determine the number of columns
# in the matrix prior to allowing clients to call methods on the object.

    return scalar @{$_[0]->_validColumnsArrayRef};

}

######################################################################
sub errstr{
#######################################################################
# This method returns the last error string that resulted from a method 
# call.  Calling the method deletes any previously held error string.
#
# Usage example:
#
# print "An error occured : ", $matrix->errstr, "\n";
#

   my ($self) = @_;

   my $error = $self->{$kErrstr};

   delete $self->{$kErrstr};

   return $error;

}

#######################################################################
sub allowedOperators{
#######################################################################
# This public method returns an array of all the allowed operators that
# may be used by methods (in subclasses) that employ the operators for
# whatever reason.
#
# Usage : my @operators = $matrix->allowedOperators;
#

    my ($self) = @_;

    return (sort keys %kAllowedOperators);

}

=pod

=head1 Name

Microarray::DataMatrix - abstraction to matrices of microarray data

=head1 Abstract and Overall Logic

Note : This documentation is for Developers only.  Clients of concrete
subclasses of this package should have no need to consult this
documentation, as the API for those subclasses should be fully
documented as part of those subclasses.

dataMatrix provides an abstract superclass for a collection of
abstract classes pertaining to dealing with matrices.  Only in the
context of the those other classes is baseDataMatrix useful and
meaningful.  baseDataMatrix itself provides protected methods for
certain primitive operations that can be used by its subclasses, and
public methods for which it is required that its immediate subclasses
have the same underlying structure to deal with their dataMatrix, such
as which rows and columns have not yet been filtered out.

The collection of classes are structured like this:


		    dataMatrix

			/\
		       /  \
                      /    \
                ISA  /	    \ ISA
		    /	     \
		   /	      \
		  /	       \
	smallDataMatrix  bigDataMatrix
		\		/
		 \	       /
		  \	      /
		   \	     /
	   CanBeA   \	    /  CanBeA
		     \	   /
		      \	  /
		       \ /
		 anySizeDataMatrix

			|
			| ISA
			|
                ------------------  -  -  -  -  -  -
		|		|		   |
		|		|		   |
		|		|		   |
	concreteClassA	concreteClassB        concreteClassX


anySizeDataMatrix provides an abstraction to a dataMatrix whose
contents may or may not fit into memory.  An object will inherit
dynamically, at construction time, from either small- or
bigDataMatrix, which know how to deal with a matrix of a particular
size.  anySizeDataMatrix itself is an abstract class, and will be
subclassed by concrete classes dealing with a particular file type of
data, which they know how to parse, for example a pclFile.  Because
development of dataMatrix, smallDataMatrix, bigDataMatrix and
anySizeDataMatrix was done as a collection of classes, they are
somewhat more intimate with each other than say a concrete subclass of
anySizeDataMatrix would be with anySizeDataMatrix itself.  While the
subclasses do stick to the API, and respect the privacy of attributes
and methods, the API was developed simultaneously with the subclasses
that were using it.  Thus it may not be the cleanest API in the
world.....

This collection of classes tries to follow the rules that all
attributes are preceded by the "$PACKAGE::", in the objects hash.
Private attribute names and private methods are preceded by two
underscores, protected attributes and protected methods (which can be
accessed by subclasses, as well as in $PACKAGE itself) are preceded by
a single underscore.  Public attributes and methods (which can be
accessed anywhere) have no preceding underscores.  In actuality, all
object attributes are (and should be private).  If there is a need for
either subclasses or clients to manipulate or access them, then there
are provided protected and public methods respectively, for setting or
getting the values of the attributes.  Disobey this interface at your
peril!!!!

=head1 Protected Setter/Mutator Methods

=head2 _setAutoDump

This protected method is used to set the autodump flag, which can be
either 1 or 0.  This should only be utilized by subclasses, not
clients.

Usage:

	$self->_setAutoDump(1);

=head2 _setValidColumns

This protected setter method receives a reference to a hash, which has
as its keys the indexes of the columns in the matrix which are valid.
This method MUST be used when the matrix has been first read, to set
up all the columns which are initially valid (this call will actually
occur in the _init methods (or methods called by them) of big- and
smallDataMatrix).  The values of the hash will usually be undef, to
simply save space.  There is no expectation for them to be otherwise.

Usage: 

       $self->_setValidColumns(\%validColumns);

=head2 _setValidRows

This protected setter method receives a reference to a hash, which has
as its keys the indexes of the rows in the matrix which are valid.
This method is expected to only be used when the matrix has been first
read, to set up all the rows which are initially valid (this call will
actually occur in the _init methods (or methods called by them) of
big- and smallDataMatrix).  The values of the hash will usually be
undef, to simply save space.  There is no expectation for them to be
otherwise.

Usage:

	$self->_setValidRows(\%validRows);

=head2 _setErrstr

This protected setter method accepts a scalar, that will correspond to
an error that has occurred, and will store it within the object.

Usage:

	$self->_setErrstr($error);

=head2 _invalidateMatrixRow

This protected mutator method makes a row invalid.  This method is not
undoable, because the invalidation also deletes the data for the row.
Note that the row index MUST correspond to the index of that row in
the original file, not whatever row it may currently be (ie if rows 1
and 2 were filtered out, row 3 should still be called row 3 when being
invalidated, not row 1).

Usage :

	$self->_invalidateMatrixRow($row);

=head2 _invalidateMatrixColumn

This protected mutator method makes a column invalid.  Note that the
column index MUST correspond to the index of that column in the original
file, not whatever column it may currently be (ie if columns 1 and 2 were
filtered out, column 3 should still be called column 3 when being
invalidated, not column 1).

Usage : 

      $self->_invalidateMatrixColumn($column);

=head1 PROTECTED GETTER/ACCESSOR METHODS

=head2 _autoDump

This protected method returns a boolean to indicate whether
autodumping is enabled.

Usage:

	if ($self->_autoDump){ 

	   # blah 

	}

=head2 _validRowsArrayRef

This protected accessor returns a reference to an array that contains
the indexes of all the valid rows

Usage:

	foreach my $row (@{$self->_validRowsArrayRef}){

		# do something useful

	}

=head2 _validColumnArrayRef

This protected accessor returns a reference to an array that contains
the indexes of all the valid columns.

Usage:

	foreach my $column (@{$self->_validColumnsArrayRef}){

		# do something useful

	}

=head2 _matrixRowIsValid

This protected accessor returns a boolean to indicate whether a given
row in the data matrix is still valid (ie has not been filtered out).
The row index is with respect to its index in the original file that
was used to construct the object.

Usage : 

      if ($self->_matrixRowIsValid($row)){ # blah }

=head2 _matrixColumnIsValid

This protected accessor returns a boolean to indicate whether a given
column in the data matrix is still valid (ie has not been filtered
out).  The column index is with respect to its index in the original
file that was used to construct the object.

Usage :

      if ($self->_matrixColumnIsValid($column)){ # blah }

=head2 _numColumnsToReport

This protected method returns the number of columns to process after
which reporting should be done, if verbose reporting has been
indicated.  If no value has been set, then the default of 50 is
returned.

Usage :

      my $numColumnsToReport = $self->_numColumnsToReport;

=head2 _numRowsToReport

This protected method returns the number of rows to process after
which reporting should be done, if verbose reporting has been
indicated.  If no value has been set, then the default of 5000 is
returned.

Usage :

      my $numRowsToReport = $self->_numRowsToReport;

=head2 _lineEnding

This protected method returns the appropriate line ending, for text or
html reporting.  It expects a string, either 'html' or 'text' and will
return the appropriate line ending.

Usage:

	my $lineEnding = $self->_lineEnding("text");

=head2 _centeringMethodIsAllowed

This protected method returns a boolean to indicate whether a
centering method is allowed.  Allowed methods are 'mean' and 'median'.

Usage : 

      if ($self->_centeringMethodIsAllowed($method)){ # blah }

=head2 _operatorIsAllowed

This protected method returns a boolean to indicate whether a
particular operator is allowed.  For each operator, there exists a
corresponding method that uses that operator.  Such operators are used
when filtering rows by there values, eg >, or < etc.


Usage : 

      if ($self->_operatorIsAllowed($operator)){ # blah }

=head2  _methodForOperator

This protected method returns the name of the method that is used to
compare two values, based on the operator that was passed in.

Usage : 

      my $method = $self->_methodForOperator($operator);

=head1 PROTECTED UTILITY METHODS

=head2 _rowAverage

This method returns the average of the valid entries in a row, using
either the mean or the median, depending on the requested method.  The
row is passed in as a reference to an array containing the values for
the row.  If no mean/median could be calculated, then the method
returns undef.  Only values at validRowIndexes within the passed in
array are used in the calculation.

Usage:

	my $average = $self->_rowAverage(\@row, "mean");

=head2 _average

This method calculates either the mean or median of a set of data, by
receiving the total number of datapoints, an array by reference of all
the datavalues, and the sum total of all the datapoints.  The former
is required to calculate the median (and is not assumed to be sorted),
the latter to calculate the mean.  The method must also be passed in.
The number of datapoints must be non-zero.

Usage:

	my $average = $self->_average("mean", \@data, $total, $numDatapoints);

=head2 _centerRow

This protected method takes an array reference to a row, and the
average (either mean or median, depending on what was requested), and
subtracts that value from every valid value (ie for the valid column
indexes) in the row.

Usage:

	$self->_centerRow(\@row, $average);

=head2 _calculateMeansAndStdDeviations

This method expects to receive hashes of the sums of X, the sums of X
squared and the number of datapoints, where the keys for each hash are
the unique identifiers for a series of numbers, whose mean and
standard deviations are to be calculated.  It returns references to
hashes that hash the same ids to the means and standard deviations.
It uses the n-1 version of standard deviation.  If a standard
deviation cannot be calculated, it will be stored as undef.

Usage:

	my ($stddevHashRef, $meansHashRef) = $self->_calculateMeansAndStdDeviations(\%sumOfX, \%sumX2, \%numDataPoints);

=head2 _calculateBounds

This method receives two hashes by reference.  One is a hash of means,
the other a hash of std deviations.  It also receives a multiplier.
It then calculates, and returns as hash references, the upper and
lower bounds for the mean plus or minus that number of deviations.  It
also receives what line ending it should be using, if being verbose in
its reporting.

Usage:

	my ($upperHashRef, $lowerHashRef) = $self->_calculateBounds($stddevHashRef, $meansHashRef, $deviations, $lineEnding);

=head2 _giveOverrideMessage

This protected utility method can be used by any subclass that expects
its own subclasses to implement certain methods.  It can have stub
methods, that simply call this method, which will give a standard
error message saying that the class 'X' must override method Y.

Usage:

	$self->_giveOverrideMessage();

=head1 PUBLIC ACCESSOR METHODS

=head2 allowedOperators

This public method returns a sorted array of all the allowed operators that
may be used by methods (in subclasses) that employ the operators for
whatever reason (their interface should indicate that they employ such
operators).

Usage : 

    my @operators = $matrix->allowedOperators;

=head1 PUBLIC SETTER METHODS

=head2 setNumColumnsToReport

This method accepts a positive integer, that indicates the number of
columns that have been processed during a filtering/transformation
method that is carried out on a column basis, after which progress
should be indicated.  If a client has not set this value, then it
defaults to 50.

Usage : 

    $matrix->setNumColumnsToReport(50);

=head2 setNumRowsToReport

This method accepts a positive integer, that indicates the number of
rows that have been processed during a filtering/transformation method
that is carried out on a row basis, after which progress should be
indicated.  If a client has not set this value, then it defaults to
5000.

Usage : 

    $matrix->setNumRowsToReport(5000);

=head1 AUTHOR

Gavin Sherlock

sherlock@genome.stanford.edu

=cut
