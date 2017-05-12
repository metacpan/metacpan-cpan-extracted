package Microarray::DataMatrix::AnySizeDataMatrix;

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

# This package is intended to provide an abstraction layer to a
# dataMatrix of anysize, whether or not all of its associated data
# will fit into memory.  It is an abstract class, and requires that a
# concrete subclass be created to take advantage.  Such concrete subclasses
# may include pclFile, or cdtFile.

# The constructor of an inheriting subclass MUST call this class's
# _init method immediately after blessing the object's hash, before
# any other methods are called on the object.

# Upon calling of the _init method, it will be determined whether the
# contents of the matrix used for construction will fit into memory or
# not, and then as appropriate, inherit from either smallDataMatrix,
# or from bigDataMatrix at runtime.

use strict;
use Carp;
use vars qw ($AUTOLOAD @ISA);

$| = 1; # set autoflush, so that reporting will flush immediately

# use both big and small DataMatrix - decide at runtime which to
# inherit from

use Microarray::DataMatrix::SmallDataMatrix;
use Microarray::DataMatrix::BigDataMatrix;

####################################################################
#
# CLASS GLOBALS
#
####################################################################

# The following globals are used so we only ever access hash entries
# (ie object attributes) using variables, to prevent typos, or
# accidental clobberring.

# These values are assigned here and then are READ-ONLY.

my $PACKAGE = 'Microarray::DataMatrix::AnySizeDataMatrix'; # will use to prefix all hash
                                               # entries which will prevent
                                               # collision with any attributes in
                                               # super or sub classes.

my $kTmpDir = $PACKAGE.'::__tmpDir'; # hold tmp directory

my $kFile             = $PACKAGE.'::__file';            # name of the file
my $kFh               = $PACKAGE.'::__fh';              # file handle
my $kFileForReading   = $PACKAGE.'::_fileForReading';   # allow superclass to specify a different file

# This variable maps the size to the superclass that should be used

my %kSizesToClasses = ('BIG'   => 'Microarray::DataMatrix::BigDataMatrix',
		       'SMALL' => 'Microarray::DataMatrix::SmallDataMatrix');

########################################################################
sub _init{
########################################################################
# This method initializes the dataMatrix, such that it will inherit
# from the correct superclass, based on its size.  The constructor of
# any concrete subclasses of anySizeDataMatrix MUST call this method
# in their constructors, immediately after blessing the object reference.
#
# A single argument, a directory that can be used to write tmp files if
# necessary, must be provided.
#
# usage : $self->_init($tmpDir), or $self->SUPER::_init($tmpDir);

    my ($self, $tmpDir) = @_;

    $self->__setTmpDir($tmpDir);

    # decide who we inherit from, based on size of matrix
    
    @ISA = ($kSizesToClasses{$self->__size});

#    print "ISA :".$self->__size."::".$kSizesToClasses{$self->__size}."\n";

    # then call superclass's _init method, which will 'do the right thing'
    
    $self->SUPER::_init();

}

######################################################################
sub __size{
######################################################################
# This private method is used to either find out if the size of the
# dataMatrix, e.g. "SMALL" or "BIG".  It is only used within this
# class (ie private), and is only called once, from the _init method.
#
# Usage : if ($self->__size eq "SMALL"){ 
#
#                    # blah
#
#         }
#

    my ($self) = @_;
    
    # here we work out how many entries will be in the matrix.  First
    # find out how much memory this user is allowed per process, then
    # combine this with an estimate of space required per matrix
    # entry.  Then decide whether it will all fit in memory.
    
    my $numColumns = $self->_numDataColumns;
    my $numRows    = $self->_numDataRows;

    print "column: $numColumns  rows: $numRows\n";
    
    my $numMatrixEntries = $numColumns * $numRows;
    
    my $limit = `/usr/bin/ulimit -d`; # find out how much memory is allowed
    
    chomp $limit;
    
    if ($limit eq "unlimited"){ # it's unlimited, but let's impose a max
	
	$limit = 200000;
	
    }

    # limit is in kilobytes, so convert to bytes, as our estimates are in bytes

    $limit *= 1000;
    
    my $memEstPerDatum   = 10;  # probably an overestimate of 25 bytes per matrix entry
    my $memMetaEstPerRow = 200; # estimate of memory for meta information per row
    my $fudgeFactor      = 7.5;   # assume it takes seven times as much memory....

    my $requiredMem      = ($numMatrixEntries * $memEstPerDatum) + ($numRows * $memMetaEstPerRow);
    
    if ($requiredMem * $fudgeFactor > $limit){ # won't fit in memory

	return ("BIG");
	
    }else{

	return ("SMALL");
	
    }
    
}

####################################################################
sub __setTmpDir{
####################################################################
# This private method is used to set the tmp directory where any tmp
# files may be written.
#
# Usage:
#
# $self->__setTmpDir($tmpDir);
    
    my ($self, $tmpDir) = @_;

    if (!-e $tmpDir){

	die "The tmp directory that was supplied, $tmpDir, does not exist.\n";

    }elsif (!-d $tmpDir){

	die "The tmp directory that was supplied, $tmpDir, is not a directory.\n";

    }elsif (!-w $tmpDir){

	die "The tmp directory that was supplied, $tmpDir, is not writable.\n";

    }

    $self->{$kTmpDir} = $tmpDir;

}

####################################################################
sub _tmpDir{
####################################################################
# This protected method returns the tmp directory that was set during
# initialization.
#

    return $_[0]->{$kTmpDir};

}

#
# ** Methods for dealing with the file that is being used
# ** to hold the dataMatrix.
#

############################################################
sub _setFile{
############################################################
# This protected method simply takes a fully qualified filename
# as an argument, checks if it exists, and if so enters it
# into the object's hash.  If not, it will die with a usage
# message.
#
# Usage : $self->_setFile($file);

    my ($self, $file) = @_;

    if (-e $file){

	$self->{$kFile} = $file;

    }else{

	$self->_usage("$file does not exist");

    }

}

######################################################################
sub file{
######################################################################
# This method returns the fully qualified name of the file that was used
# to instantiate the object
#
# Usage : my $file = $matrix->file;
#

    return $_[0]->{$kFile};

}

######################################################################
sub _setFileForReading{
######################################################################
# This method allows setting of the file that should be read, eg as a
# superclass may use temporary files on disk, that it needs this class
# to read from instead

    my ($self, $fileName) = @_;

    $self->{$kFileForReading} = $fileName; # record the new file
    $self->_fileHandle(reset=>1);         # reset the file handle

    return $_[0]->{$kFileForReading};

}

######################################################################
sub _fileForReading{
######################################################################
# This method returns the name of the file that is currently meant to
# be read.

    return $_[0]->{$kFileForReading};

}

######################################################################
sub _fileHandle{
######################################################################
# This method returns a file handle on the dataMatrix file that was
# used to instantiate the object, or on a file that it has been told
# is for reading.  This second reason is so that the base class can
# communicate with the subclass, to indicate that a new tmp file
# exists that should be used as the data source.  If it receives a
# true value for the 'reset' argument, it will close any open file
# handle, then reopen a handle on the file.  In doing so, it shall
# reset the current file data row to a value of -1.

    my ($self, %args) = @_;

    if ($args{'reset'} && exists $self->{$kFh}){ # want to start from beginning

	close $self->{$kFh};  # close an existent file handle

	delete $self->{$kFh}; # get rid of the defunct handle

    }

    if (!exists $self->{$kFh}){ # open a handle if we need to

	local *FH;
	
	my $file = $self->_fileForReading || $self->file;

	open(FH, $file) || die "Couldn't open $file : $!\n"; # need an error handling strategy here
	
	$self->{$kFh} = *FH;

	$self->_setFileHandleToStart; # tell subclass that file handle is at beginning

    }

    return $self->{$kFh};

}


#
# ** METHODS THAT MUST BE OVERIDDEN BY CONCRETE SUBCLASSES
#

####################################################################
sub _numDataRows{
####################################################################

    $_[0]->_giveOverrideMessage();

}

####################################################################
sub _numDataColumns{
####################################################################

    $_[0]->_giveOverrideMessage();

}

####################################################################
sub _dataLine{
####################################################################

    $_[0]->_giveOverrideMessage();

}

####################################################################
sub _printLeadingMeta{
####################################################################

    $_[0]->_giveOverrideMessage();

}
    
####################################################################
sub _printRow{
####################################################################

    $_[0]->_giveOverrideMessage(); 

}

####################################################################
sub _printTrailingMeta{
####################################################################

    $_[0]->_giveOverrideMessage(); 

}


#
# ** DATA TRANSFORMATION METHODS
#

####################################################################
sub AUTOLOAD{
####################################################################
# The AUTOLOAD method is called by perl if a method canot be resolved.
# It will be used for all public data transformation methods, so that
# they can all be easily be wrapped in an eval, and report errors
# appropriately.  The public interface will define the method as being
# called one thing, but it will be implemented in the object with a
# leading underscore on the name.  It will thus be caught by AUTOLOAD,
# before being dispatched inside an eval clause.

# All the actual data transformation methods are implemented in the
# superclass that is specific to a particular size of dataMatrix.  The
# internal dispatching is dealt with by methods within this class
# (which have common elements, irrespective of the size of matrix),
# but the actual specifics are dealt with in the superclass.  If the
# superclass method is named the same as the generic method in this
# class, it is called using the $self->SUPER::method() syntax.

    my ($self, %args) = @_;

#    my $caller = (caller(1))[3];
#
#    print "Called by : $caller (calling $AUTOLOAD)\n";
#
#    foreach my $key (keys %args){
#
#	print $key, "=> '", $args{$key}, "'\n";
#
#    }

    if ($AUTOLOAD =~ /.*::(\w+)/){ # get method name

	my $method = "_".$1; 

	# check to see if method is allowed

	if ($self->can($method)){

	    # check to see if any errors occurred during method running

	    eval {

		$self->$method(%args);

	    };

	    if ($@){

		$self->_setErrstr($@); # store the error message
		
		print STDERR "$@\n";

		return 0; # 0 means failure
		
	    }else{

		if ($self->_autoDump){

		    print "Dumping data.\n";

		    $self->dumpData($args{'file'});

		}

		return 1; # 1 means success
		
	    }

	}

    }

    # if we get here, they called a method that wasn't allowed

    die "No such method: $AUTOLOAD";

}

# The following methods are public, but called via the autoloading
# mechanism, without the leading underscore :
#
# _center, _filterByPercentPresentData, _filterRowsOnColumnPercentile,
# _filterRowsOnColumnDeviation, _filterRowsOnValues, _filterRowsOnVectorLength
# _logTransformData, _scaleColumnData


######################################################################
sub _center{
######################################################################

# This method allows either rows or columns of the dataMatrix to be
# centered using either means or medians.  If centering both rows and
# columns, centering will be done iteratively, until no datapoint
# changes by more than 0.01.  Alternatively, the maxNumIterations can
# be specified, or the maxAllowableChange can be specified.  If used
# in combination, the first one that is met will terminate centering.
# The defaults are:

# maxAllowableChange  0.01 
# maxNumIterations      10
#
# Usage: eg:
#
#	$dataMatrix->center(rows=>'mean',
#			    columns=>'median');
#

    
    my ($self, %args) = @_;

    my $maxAllowableChange = $args{'maxAllowableChange'} || 0.01;
    my $maxNumIterations   = $args{'maxNumIterations'}   || 10;

    my $centerRowsMethod    = $args{'rows'};
    my $centerColumnsMethod = $args{'columns'};

    my $message = ""; # to hold any error message

    if (defined($centerRowsMethod) && !($self->_centeringMethodIsAllowed($centerRowsMethod))){

	$message .= "\"$centerRowsMethod\" is not a recognized method for centering rows.\n";

    }elsif (defined $centerColumnsMethod && !$self->_centeringMethodIsAllowed($centerColumnsMethod)){

	$message .= "\"$centerColumnsMethod\" is not a recognized method for centering columns.\n";

    }

    $message && die $message;

    my $lineEnding         = $self->_lineEnding($args{'verbose'}) if (exists $args{'verbose'});
    my $numColumnsToReport = $self->_numColumnsToReport;
    my $numRowsToReport    = $self->_numRowsToReport;
    
    if ($centerRowsMethod && $centerColumnsMethod){
	
	my $iteration = 1;
	
	while (1){	    
	    
	    if (defined $lineEnding && $maxNumIterations > 1){
		
		print "Iteration ", $iteration, $lineEnding;
		
	    }
	    
	    my $maxChange = $self->_centerColumns($centerColumnsMethod, $lineEnding, $numColumnsToReport);
	    $self->_centerRows($centerRowsMethod, $lineEnding, $numRowsToReport);
	    
	    $iteration++;
	    
	    last if $iteration >= $maxNumIterations;
	    last if $maxChange <  $maxAllowableChange;

	}	    

    }elsif ($centerRowsMethod){

	$self->_centerRows($centerRowsMethod, $lineEnding, $numRowsToReport);

    }elsif ($centerColumnsMethod){

	$self->_centerColumns($centerColumnsMethod, $lineEnding, $numColumnsToReport);

    }

}

   
######################################################################
sub _filterByPercentPresentData{
######################################################################
# This method allows for filtering out of rows or columns which do not
# have greater than the specified percentage of data available.  Note,
# if filtering by both rows and columns, filtering will be done
# sequentially, firstly by rows.  To overide this, make two seperate
# calls to the method, in the opposite order.  There is no fancy
# algorithm to maximize the amount of retained data (eg consider
# filter by rows, then by columns, that removal of a column means that
# some rows thrown out in the first step may have greater than 80%
# good data for the remaining columns - this method does not consider
# this).
#
#	$dataMatrix->filterByPercentPresentData(rows=>80,
#                                               columns=>80);
#
#	$dataMatrix->filterByPercentPresentData(rows=>90,
#						filename=>$filename);

    my ($self, %args) = @_;
    
    my $lineEnding = $self->_lineEnding($args{'verbose'}) if (exists $args{'verbose'});
    
    if (!exists($args{'rows'}) && !exists($args{'columns'})){
	
	die "filterByPercentPresentData requires you to specify either rows or columns to be filtered.\n";
	
    }
    
    if (exists($args{'rows'})){
	
	if ($args{'rows'} >= 100 || $args{'rows'} < 0){
	    
	    die "You must specify percent present data greater than or equal to 0 and less than 100.\n";
	    
	}
	
	defined $lineEnding && print ("Filtering out rows with less than $args{'rows'}\% present data", $lineEnding);
	
	$self->_filterRowsByPercentPresentData($args{'rows'}, $lineEnding, $self->_numRowsToReport);
	
    }
    
    if (exists($args{'columns'})){
	
	if ($args{'columns'} >= 100 || $args{'columns'} < 0){
	    
	    die "You must specify percent present data greater than or equal to 0 and less than 100.\n";
	    
	}
	
	defined $lineEnding && print ("Filtering out columns with less than $args{'columns'}\% present data", $lineEnding);

	$self->_filterColumnsByPercentPresentData($args{'columns'}, $lineEnding, $self->_numColumnsToReport);

    }
    
}

######################################################################
sub _filterRowsOnColumnPercentile{
######################################################################
# This method will filter out rows whose values do not have a
# percentile rank for their particular column above a specified
# percentile rank, in at least numColumns columns.  Note it only
# considers rows and columns that have not been filtered out by ant
# previous method calls.
#
# Usage:
#
#	$dataMatrix->filterRowsOnColumnPercentile(percentile=>95,
#                                                  numColumns=>1);

# To actually do this, we need to look at each column of data, sort
# it, while tracking the row to value mapping, and see which of the
# rows are above the requested percentile, and keep a count of them.
# The method use here simply for each column in turn creates a hash of
# row number to value (for those that have values - it does not
# consider the empty ones).  It then sorts those keys by their values,
# and puts the keys in that order into an array.  It then looks at
# those array elements that correspond to the required percentile, and
# keeps a count of the rows in that percentile.  After doing this for
# all columns, it filters out rows that don't have a high enough
# count.

    my ($self, %args) = @_;

    if (!exists($args{'percentile'})){

	die "You must specify a percentile argument for filterRowsOnColumnPercentile.\n";

    }

    if (!exists($args{'numColumns'})){

	die "You must specify a numColumns argument for filterRowsOnColumnPercentile.\n";

    }

    if ($args{'percentile'} <= 0 || $args{'percentile'} >= 100){

	die "You must specify the percentile argument as greater than 0 and less than 100.\n";

    }

    if ($args{'numColumns'} <= 0){

	die "You cannot specify the numColumns argument as less than or equal to zero.\n";

    }

    my $lineEnding = $self->_lineEnding($args{'verbose'}) if (exists $args{'verbose'});
    my $numColumnsToReport = $self->_numColumnsToReport;
    my $showPercentile = $args{'showPercentile'} || 0;

    defined $lineEnding && print ("Filtering rows by column percentile rank", $lineEnding);

    $self->SUPER::_filterRowsOnColumnPercentile($lineEnding, $numColumnsToReport, $args{'percentile'}, $args{'numColumns'}, $showPercentile);

}

######################################################################
sub _filterRowsOnColumnDeviation{
######################################################################
# This method will filter out rows whose values do not deviate from
# the column mean by a specified number of standard deviations, in at
# least numColumns columns.
#
# Usage:
#
#	$dataMatrix->filterRowsOnColumnDeviation(deviations=>2,
#						 numColumns=>1);

    my ($self, %args) = @_;

    if (!exists($args{'deviations'}) || $args{'deviations'} <= 0){

	die "You must supply a deviations argument with a value greater than zero.\n";

    }

    if (!exists($args{'numColumns'}) || $args{'numColumns'} < 1){

	die "You must supply a numColumns argument with a value greater than or equal to 1.\n";

    }

    my $lineEnding = $self->_lineEnding($args{'verbose'}) if (exists $args{'verbose'});
    my $numRowsToReport = $self->_numRowsToReport;
    my $deviations = $args{'deviations'};
    my $numColumns = $args{'numColumns'};

    $self->SUPER::_filterRowsOnColumnDeviation($lineEnding, $numRowsToReport, $deviations, $numColumns);

}

######################################################################
sub _filterRowsOnValues{
######################################################################
# This method filters out rows whose values do not pass a specified
# criterion, in at least numColumns columns.  To specify the criterion, a
# value, and an operator must be specified.  The valid operators are:
#
# "absolute value >"  also aliased by "absgt"   and "|>|" 
# "absolute value >=" also aliased by "absgteq" and "|>=|"
# "absolute value ="  also aliased by "abseq"   and "|=|"
# "absolute value <"  also aliased by "abslt"   and "|<|"
# "absolute value <=" also aliased by "abslteq" and "|<=|"
# ">"                 also aliased by "gt"
# ">="                also aliased by "gteq"
# "="                 also aliased by "eq"      and "=="
# "<="                also aliased by "lteq"
# "<"                 also aliased by "lt"
# "not equal"         also aliased by "ne"      and "!="
#
# Usage:
#
#	$dataMatrix->filterRowsOnValues(operator=>"absolute value >",
#					value=>2,
#					numColumns=>1);

    my ($self, %args) = @_;

    if (!exists ($args{'operator'}) || !defined ($args{'operator'})){

	die "You must supply an operator argument for the filterRowsOnValues method.".
	    
	    "Available operators are: ".join("\n", $self->allowedOperators)."\n";

    }elsif (!$self->_operatorIsAllowed($args{'operator'})){

	die "The operator argument you supplied for the filterRowsOnValues method is not allowed.".

	    "Available methods are: ".join("\n", $self->allowedOperators)."\n";

    }

    if (!exists($args{'value'}) || !defined($args{'value'})){

	die "You must supply a value to the filterRowsOnValues method.\n";

    }

    my $value = $args{'value'};

    my $method = $self->_methodForOperator($args{'operator'});

    my $lineEnding = $self->_lineEnding($args{'verbose'}) if (exists $args{'verbose'});

    my $numColumns = $args{'numColumns'};

    defined $lineEnding && print ("Filtering rows based on $args{'operator'} $value in $args{'numColumns'} columns", $lineEnding);
    
    $self->SUPER::_filterRowsOnValues($value, $method, $lineEnding, $self->_numRowsToReport, $numColumns);

}

######################################################################
sub _filterRowsOnVectorLength{
######################################################################
# This method filters out rows based on whether the vector that their
# values define has a length of greater than the specified length.
#
# Usage:
#
#	$dataMatrix->filterRowsOnVectorLength(length=>2);

    my ($self, %args) = @_;
    
    if (!exists($args{'length'}) || $args{'length'} <= 0){
	
	die "You must provide a length argument with a positive value to filterRowsOnVectorLength\n";
	
    }
    
    my $requiredLength = $args{'length'};

    my $lineEnding = $self->_lineEnding($args{'verbose'}) if (exists $args{'verbose'});
    my $numRowsToReport = $self->_numRowsToReport;

    defined $lineEnding && print ("Filtering out rows whose vector length is not greater than $args{'length'}", $lineEnding);
    
    $self->SUPER::_filterRowsOnVectorLength($requiredLength, $lineEnding, $numRowsToReport); 

}

######################################################################
sub _logTransformData{
######################################################################
# This method log transforms the contents of the data matrix, using
# the specified base.  If any values less than or equal to zero are
# encountered, then the transformation will fail.  The matrix will be
# returned to its state prior to log transformation

# Usage :
#
# $dataMatrix->logTransformData(base=>2);

    my ($self, %args) = @_;

    my $base = $args{'base'};

    die "You must provide a 'base' argument whose value is greater than zero.\n" if ($base <= 0);

    my $logBase = log($base);

    my $lineEnding = $self->_lineEnding($args{'verbose'}) if (exists $args{'verbose'});
    my $numRowsToReport = $self->_numRowsToReport;

    defined $lineEnding && print ("Log transforming data in base $base.", $lineEnding);

    $self->SUPER::_logTransformData($logBase, $lineEnding, $numRowsToReport);

}

######################################################################
sub _scaleColumnData{
######################################################################
# This method scales the data for particular columns as specified by
# the client, by dividing the values by specified factors.  It could,
# for instance, be used to renormalize the data (only if the data are
# in ratio form).
#
# The client passes in a hash, by reference, of the column number
# (starting from zero) as the key, and the scaling factor as the
# value.
#
# Usage:
#
# $datamatrix->scaleColumnData(columns=>{0=>1.2,
#                                        2=>0.8});
#
#
# If a column number which is invalid is specified, then a warning to
# STDERR will be printed.  Also, if a scaling factor of zero (or
# undef) is supplied for a column, a warning will be printed, and the
# zero will not be used.

    my ($self, %args) = @_;

    my $columnsToFactorsHashRef = $args{'columns'} || die "You must supply a columns argument to scaleColumnData.\n";

    my $lineEnding = $self->_lineEnding($args{'verbose'}) if (exists $args{'verbose'});
    my $numColumnsToReport = $self->_numColumnsToReport;

    defined $lineEnding && print ("Scaling column data.", $lineEnding);

    $self->SUPER::_scaleColumnData($columnsToFactorsHashRef, $lineEnding, $numColumnsToReport);

}

sub DESTROY{

}

1; # to keep Perl happy


=pod

=head1 NAME

Microarray::DataMatrix::AnySizeDataMatrix - abstraction to DataMatrix

=head1 Abstract

anySizeDataMatrix.pm provides an abstraction layer to a dataMatrix, in
that it provides methods for manipulating or querying the contents of
a dataMatrix.  anySizeDataMatrix is an abstract class - thus
anySizeDataMatrix objects themselves cannot be instantiated - only
objects of concrete subclasses can be instantiated.

=head1 Overall Logic

This is for programmers only - do not rely on any of these details
when programming clients of the concrete subclasses of
anySizeDataMatrix, or programming the subclasses themselves, as the
underlying implementation is subject to change at any time without
notice.  Just stick to using the API!  (described below).

Implementation of an anySizeDataMatrix depends on its size.  Upon
construction of concrete subclass, anySizeDatamatrix will determine if
the matrix is too big to fit into memory.  It then dynamically
inherits from either smallDataMatrix, or bigDataMatrix.  In the case
that anySizeDataMatrix decides to inherit from smallDataMatrix, then
all data are read into memory, and the actual data matrix from the
file (used to instantiate the concrete subclass) is stored as a 2
dimensional array.  The indexes of the array which are still valid
(following some filtering step) are stored in internal hashes, such
that subsequent manipulations of the data only consider the data that
have not been filtered out.  As rows or columns are filtered out by
some of the methods, the entries for these rows or columns are deleted
from the hashes that track valid data.  Thus when data are redumped to
a file, only those data that have not been filtered are printed out.

When anySizeDatamatrix instead inherits from bigDataMatrix, because a
matrix is too large to be read into memory, then all operations are
carried out on disk versions of the matrix.  This is obviously less
efficient, as it often requires the file to be read multiple times,
and intermediate results to be stored in tmp files.  

Whether the matrix fits into memory or not, all reading and writing of
files is carried out by methods that have to be implemented in the
concrete subclass, though the matrix class itself (small or big)
actually deals with calling them appropriately in its own methods.

For all the data transformation / filtering methods, the methods are
actually autoloaded in anySizeDatamatrix, then redispatched to
protected versions of the method, and then again dispatched to
protected methods within small and bigDataMatrix.  This is done so
that thay can all be wrapped by a generic eval clause, which only
needs to appear once in the AUTOLOAD method.

Construction of objects is up to the client subclasses to implement,
as anySizeDatamatrix has no new() method.  Upon object construction, a
concrete subclass must call the _init method of anySizeDatamatrix,
giving it the name of the tmp directory that can be used for storage
of any temp files.  _init is defined thus:

=head2 _init

This method initializes the dataMatrix, such that it will inherit from
the correct superclass, based on its size.  The constructor of any
concrete subclasses of anySizeDataMatrix MUST call this method in
their constructors, after blessing the object reference, but before
returning it to the client.  The _init method will call the
_numDataRows and _numDataColumns methods that the subclass must
implement (see below) during initialization.  Thus the concrete
subclass must take care of any of its own initialization that will be
required for these to work correctly, prior to calling the
anySizeDataMatrixs _init() method.

A single argument, a directory that can be used to write tmp files if
necessary, must be provided to _init.

Usage : 

      $self->_init($tmpDir)

or 

      $self->SUPER::_init($tmpDir);


=head1 Methods that must be implemented by concrete subclasses.

=head2 _numDataRows

This method should return the number of rows that can be expected to
be read from the file with which the object was instantiated.

Usage:

	my $numRows = $self->_numDataRows;

=head2 _numDataColumns

This method should return the number of data columns that can be
expected from the file with which the object was instantiated.

Usage:

	my $numColumns = $self->_numDataColumns;

=head2 _dataLine

This method should return the requested row of data from the file
whose name is available from the _fileForReading() method.  It should
return a reference to an array of the data.  Null values in the line
of data should be dealt with as blanks in the array.  A requested row
number of zero means the first line of data in the file.  If no line
of data corresponds to the requested row number, then undef should be
returned.

Usage:

	my $dataArrayRef = $self->_dataLine($lineNo);

=head2 _printLeadingMeta

This method should print the leading meta data from that corresponds
to the file from which the object was instantiated.

Usage:

	$self->_printLeadingMeta($fh, $validColumnsArrayRef,
				 $hasExtraInfo, $extraInfoName);

where: 

$fh is a file handle to which the information should be printed.

$validColumnsArrayRef is a reference to an array of column numbers of
the columns that are still valid in the dataMatrix.  The column
numbers are with respect to the columns in the original file with
which the object was instantiated.

$hasExtraInfo is a boolean to indicate whether extra information
should be interleaved with the data.

$extraInfoName is the name of the extra information.

Note these last two are to support the interleaving of percentile data
into a datafile.  This will probably be removed, such that a separate
percentiles file, or any other type of extra information file is
created instead.  This is currently in here as legacy support.

=head2 _printRow

This method prints to the passed in file handle.  It will only print
information for those valid columns.  If the $extraInfo variable is
true (ie a non-zero value) it will print the extra info interleaved
between each column of data.  The extra info comes from the 2D hash
whose reference is passed in.  The relevant piece of extra information
is accessed by the row as the key of the first hash dimension, and the
columns as the key of the second hash dimension.

Usage : 

      $self->_printRow($fh, $row, $dataRef, $validColumnsArrayRef, 
		       $hasExtraInfo, $extraInfoHashRef);

=head2 _printTrailingMeta

This method prints out any trailing meta data to the passed in file
handle.

Usage:

	$self->_printTrailingMeta($fh, $validColumnsArrayRef,
				  $hasExtraInfo, $extraInfoName);

=head1 Protected methods that are used by both the superclass and subclasses

=head2 _setFile

This protected method simply takes a fully qualified filename as an
argument, checks if it exists, and if so stores it in the object.  If
not, it will die with a usage message.

=head2 _fileForReading

This method should return the fully qualified name of the file that is
currently holding the data.  This may change from the original file
that was used to instantiate the object, as the abstract superclass of
anySizeDatamatrix may use temp files to hold the contents of the
matrix.  If the file that the subclass is supposed to be reading data
from is changed, then it is up to the subclass to deal with that
appropriately, ie it should read from the correct file when it needs to.

Usage:

	my $file = $self->_fileForReading;

=head2 _setFileForReading

This method should allow the super class to set the file which
the concrete subclass should be using to get data.

Usage:

	$self->_setFileForReading($newFile);

=head2 _fileHandle

This method returns a file handle on the matrix file that was used to
instantiate the object, or on a file that it has been told is for
reading.  This second reason is so that the superclass can communicate
with the subclass, to indicate that a new tmp file exists that should
be used as the data source.  If it receives a true value for the
'reset' argument, it will close any open file handle, then reopen a
handle on the file.  In doing so, it shall reset the current file data
row to a value of -1.

Usage:

    my $fh = $self->_fileHandle(reset=>$reset);

=head1 Public methods implemented in the size independent anySizeDataMatrix

=head2 file

This methods returns the name of the file that was used to construct
the object.

Usage:

	my $file = $matrix->file;

returns: a scalar


=head1 Public methods, implemented in the size dependent super classes of anySizeDataMatrix.

=head2 dumpData 

This method dumps the current contents of the dataMatrix object to a
file, either whose name was provided as a single argument, or to a
file whose name was used to construct the object.  If the data have
been filtered based on columnPercentiles, and these were elected to be
shown, then these will be dumped out too (see below).

Usage:

    $dataMatrix->dumpData($file);

or:

    $dataMatrix->dumpData;

=head2 Tranformation and Filtering Methods

Developer note : The initial 'front-end' common parts to these methods
are implemented in anySizeDataMatrix, but the full, 'back-end' nuts
and bolts of each method is implemented in the relevant size dependent
super-classes, small- and bigDataMatrix, as the way in which each
deals with filtering is fundamentally different, depending on whether
they are memory constrained or not.  This does mean that any new
filtering/transformation methods that are implemented MUST be added to
both small and bigDataMatrix, potentially with some shared common code
being implemented in anySizeDataMatrix.

General note on methods that transform the data : If autodumping is
on, then by default, they will overwrite the file that was used to
create the object of the concrete subclass, unless a new filename is
passed in.  If a new filename is passed in (as an argument named
'file'), and autodumping is on, then further operations on the
dataMatrix of filtered data will operate on the already filtered data.
Note, the program MUST have permissions to overwrite the original
file, if no new filename is provided.

All of the transformation and filtering methods return 1 upon success.
If an error was encountered, then the method will return 0, and the
error message associated with the problem can be retrieved using the
errstr() method, eg:

      $dataMatrix->methodX(%args) || die "An error occured ".$dataMatrix->errstr."\n";

All of the transformation and filtering methods allow a verbose
argument to be passed in, with valid values for the verbose argument
being either 'text' or 'html'.  For text, \n will be used as an end of
line character after every line of reporting is printed.  For html,
\n<br> will be used, eg:

      $dataMatrix->center(rows=>'mean',
                          verbose=>'html') || die $dataMatrix->errstr;

=head2 center

This method allows either rows or columns of the dataMatrix to be
centered using either means or medians (centering is when the average
- mean or median - is set to zero, by subtracting the average from
every value for that row/column).  If centering both rows and columns,
centering will be done iteratively, until no datapoint changes by more
than 0.01.  Alternatively, the maxNumIterations can be specified, or
the maxAllowableChange can be specified.  If used in combination, the
first one that is met will terminate centering.  The defaults are:

    maxAllowableChange  0.01 
    maxNumIterations      10

Usage: eg:

	$dataMatrix->center(rows=>'mean',
			    columns=>'median') || die $dataMatrix->errstr;


returns : 1 upon success, or 0 otherwise

=head2 filterByPercentPresentData

This method allows for filtering out of rows or columns which do not
have greater than the specified percentage of data available.  Note,
if filtering by both rows and columns, filtering will be done
sequentially, firstly by rows.  To overide this, make two seperate
calls to the method, in the opposite order.  There is no fancy
algorithm to maximize the amount of retained data (eg consider filter
by rows, then by columns, that removal of a column means that some
rows thrown out in the first step may have greater than 80% good data
for the remaining columns - this method does not consider this).

	$dataMatrix->filterByPercentPresentData(rows=>80,
                                                columns=>80);

	$dataMatrix->filterByPercentPresentData(rows=>90,
						file=>$filename);

returns: 1 upon success, or 0 otherwise

=head2 filterRowsOnColumnPercentile

This method will filter out rows whose values do not have a percentile
rank for their particular column above a specified percentile rank, in
at least numColumns columns.  In addition, this method will accept a
'showPercentile' argument, which if set to a non-zero value, will
result in the percentiles of the datapoints being dumped out with the
data, when the data are aubsequently dumped to a file.  Columns of
percentiles are interleaved with the data columns, so the resulting
file can not be clustered.

Note: This method has not yet been implemented for matrices that do
not fit into memory, so calling it on such a matrix will produce an
error (which of course, you are always checking for).

Usage:

	$dataMatrix->filterRowsOnColumnPercentile(percentile=>95,
                                                  numColumns=>1,
						  showPercentiles=>1);


returns : 1 upon success, or 0 otherwise

=head2 filterRowsOnColumnDeviation

This method will filter out rows whose values do not deviate from the
column mean by a specified number of standard deviations, in at least
numColumns columns.

Usage:

	$dataMatrix->filterRowsOnColumnDeviation(deviations=>2,
						 numColumns=>1);

returns : 1 upon success, or 0 otherwise

=head2 filterRowsOnValues

This method filters out rows whose values do not pass a specified
criterion, in at least numColumns columns.  To specify the criterion,
a value, and an operator must be specified.  The valid operators are:

  "absolute value >"  also aliased by "absgt"   and "|>|" 
  "absolute value >=" also aliased by "absgteq" and "|>=|"
  "absolute value ="  also aliased by "abseq"   and "|=|"
  "absolute value <"  also aliased by "abslt"   and "|<|"
  "absolute value <=" also aliased by "abslteq" and "|<=|"
  ">"                 also aliased by "gt"
  ">="                also aliased by "gteq"
  "="                 also aliased by "eq"      and "=="
  "<="                also aliased by "lteq"
  "<"                 also aliased by "lt"
  "not equal"         also aliased by "ne"      and "!="


Usage:

	$dataMatrix->filterRowsOnValues(operator=>"absolute value >",
					value=>2,
					numColumns=>1);


returns : 1 upon success, or 0 otherwise

=head2 filterRowsOnVectorLength

This method filters out rows based on whether the vector that their
values define has a length of greater than the specified length.

Usage:

	$dataMatrix->filterRowsOnVectorLength(length=>2);

returns : 1 upon success, or 0 otherwise

=head2 logTransformData

This method log transforms the contents of the data matrix, using the
specified base.  If any values less than or equal to zero are
encountered, then the transformation will fail.  The matrix may be
left in an indeterminate state if the operation fails, so the object
should not be used further if the transformation is unsuccessful.

Usage :

    $dataMatrix->logTransformData(base=>2);

returns : 1 upon success, or 0 otherwise

=head2 scaleColumnData

This method scales the data for particular columns as specified by the
client, by dividing the values by specified factors.  It could, for
instance, be used to renormalize the data.  Note it is only
appropriate to normalize ratio data, not log transformed data.

The client passes in a hash, by reference, of the column numbers
(starting from zero) as the keys, and the scaling factors as the
values.

If a column number which is invalid is specified, then a warning to
STDERR will be printed.  Also, if a scaling factor of zero (or undef)
is supplied for a column, a warning will also be printed to STDERR,
and the column data for that column will not be scaled.

Usage:

    $datamatrix->scaleColumnData(columns=>{0=>1.2,
					   2=>0.8});

returns : 1 upon success, or 0 otherwise

=head1 Accessor Methods

Developer note : The following methods are actually implemented in the
dataMatrix class, which is a superclass of both small- and
bigDataMatrix.

=head2 numRows

This method returns the number of rows that are currently valid in the
data matrix.

Usage:

	my $numRows = $dataMatrix->numRows;

returns: a scalar

=head2 numColumns

This method returns the number of columns that are currently valid in
the data matrix.

Usage:

	my $numColumn = $dataMatrix->numColumns;

returns: a scalar

=head2 errstr

This method returns an error string that is associated with the last
failed call to a data transformation/filtering method.  Calling this
method will clear the contents of the error string.

=head1 Setter Methods

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

=head2 allowedOperators

This public method returns an array of all the allowed operators that
may be used by methods (in subclasses) that employ the operators for
whatever reason (their interface should indicate that they employ such
operators).

Usage : 

    my @operators = $matrix->allowedOperators;

=head1 AUTHOR

Gavin Sherlock

sherlock@genome.stanford.edu

=cut



