package Microarray::DataMatrix::CdtFile;

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

# This package is intended to provide an abstraction to a cdtFile,
# whose format is detailed at:
#
# http://genome-www5.Stanford.EDU/MicroArray/help/formats.shtml#cdt
#

use strict;
use vars qw (@ISA);

use Microarray::DataMatrix::TabDelimitedDataMatrix;
@ISA = qw (Microarray::DataMatrix::TabDelimitedDataMatrix);

# CLASS GLOBALS

# use the following so we only ever access hash entries
# using variables, to prevent typos, or accidental cloberring.

# These values are assigned here and then are READ-ONLY.

my $PACKAGE = "Microarray::DataMatrix::CdtFile";

my $kHasGID              = $PACKAGE.'::__hasGID';              # whether it has a GID column
my $kHasAID              = $PACKAGE.'::__hasAID';              # whether it has an AID line 
my $kGIDs                = $PACKAGE.'::__GIDs';                # array of GIDs
my $kAIDs                = $PACKAGE.'::__AIDs';                # array of AIDs
my $kRowNames            = $PACKAGE.'::__rowNames';            # array of row names
my $kRowDescs            = $PACKAGE.'::__rowDescs';            # array of row descriptions
my $kgWeights            = $PACKAGE.'::__gWeights';            # array of gweights in the file
my $kIdName              = $PACKAGE.'::__idName';              # name of the first column
my $kDescName            = $PACKAGE.'::__descName';            # name of the second column
my $kNumLeadingMetaLines = $PACKAGE.'::__numLeadingMetaLines'; # number of leadin lines of meta data

######################################################################
sub new{
######################################################################
# This is the constructor.  It requires that the filename of the cdt
# file that is being used to construct the object is passed in.  In
# addition you can set a variable, autodump, to indicate whether data
# should be automatically dumped out after any method call that
# transforms or filters the data.  If this is not set, then you must
# manually call the dumpData method.  The default is for autodumping
# to be off.  This is useful, for instance, because you may run
# several filters/transformations over the data, and only want to dump
# the data at the end, which is more optimal that dumping it at every
# step.
#
# Usage :
#
#	my $cdtFile = cdtFile->new(file=>$file,
#                                  autodump=>1);
#
# The constructor simply sets up the object attributes.  It does
# not read in any data.  This will be done on demand, if a method
# is called that requires the data to be read in.

    my $self = {};

    my ($class, %args) = @_;

    bless $self, $class;

    $self->_setFile($args{'file'});
    $self->{$kRowNames} = [];
    $self->{$kRowDescs} = [];
    $self->{$kgWeights} = [];

    $self->_init;

    $self->SUPER::_init($args{'tmpDir'}); # required by the anySizeMatrixClass

    $self->_setAutoDump($args{'autodump'}) if (exists($args{'autodump'}));

    return $self;

}

#####################################################################
sub _init{
#####################################################################
# This method determines whether the file has a GID column, and an AID
# row, and stores that information, and the number of leading meta
# lines.

    my ($self) = @_;

    my $fh = $self->_fileHandle(reset=>1);

    my $line = <$fh>; # grab first line

    my $lineRef = $self->_arrayRefForLine(\$line);

    if ($lineRef->[0] eq "GID"){

	$self->__setHasGID(1);

    }else{

	$self->__setHasGID(0);

    }

    $line = <$fh>; # grab second line in file

    $lineRef = $self->_arrayRefForLine(\$line);

    if ($lineRef->[0] eq "AID"){
	
	$self->__setNumLeadingMetaLines(2);
	$self->__setHasAID(1);
	
    }else{

	$self->__setHasAID(0);
	$self->__setNumLeadingMetaLines(1);

    }
    
    $self->_fileHandle(reset=>1); # reset the handle again
    
}

#####################################################################
sub __usage{
#####################################################################
# This private method prints out a usage message for the constructor,
# and then dies with a specific error message.
#
# Usage : $self->__usage("$file does not exist");

    my ($self, $error) = @_;

    print STDERR '
Usage:

	my $dataMatrix = cdtFile->new(file=>$file,
                                      autoDump=>1,
		       	              tmpDir=>$dir);

where the file is a cdt file, formatted according to :

	http://genome-www5.Stanford.EDU/MicroArray/help/formats.shtml#cdt

';


    die "$error.\n";

}

######################################################################
sub _numLeadingMetaLines{
######################################################################
# This method returns the number of leading meta lines that exist in
# the cdt file.  It will be either 1 or 2, depending on whether arrays
# were clustered or not.  It is determined at object initialization.

    return ($_[0]->{$kNumLeadingMetaLines});

}

######################################################################
sub __setNumLeadingMetaLines{
######################################################################
# This method sets the number of leading meta lines that exist in the
# file.

    my ($self, $numLines) = @_;

    if (! defined $numLines || ($numLines !=1 && $numLines !=2)){

	die "number of leading meta lines must be 1 or 2, not '$numLines'.\n";

    }

    $self->{$kNumLeadingMetaLines} = $numLines;

}	

######################################################################
sub __setHasAID{
######################################################################
# This private method allows setting of an attribute to indicate
# whether or not the cdt file has an AID row.  It expects either a 0
# or 1 to be passed in.
#
# Usage : $self->__setHasAID(0);

    my ($self, $value) = @_;

    if ($value != 0 && $value != 1){

	die "__setHasAID called with a value of $value.\nOnly 0 or 1 are allowed";

    }

    $self->{$kHasAID} = $value;

}

######################################################################
sub __setHasGID{
######################################################################
# This private method allows setting of an attribute to indicate
# whether or not the cdt file has an GID column.  It expects either a 0
# or 1 to be passed in.
#
# Usage : $self->__setHasGID(0);

    my ($self, $value) = @_;

    if ($value != 0 && $value != 1){

	die "__setHasGID called with a value of $value.\nOnly 0 or 1 are allowed";

    }

    $self->{$kHasGID} = $value;

}

######################################################################
sub __hasAID{
######################################################################
# This private method returns a boolean to indicate whether the cdt file
# has an AID row

    return $_[0]->{$kHasAID};

}

######################################################################
sub __hasGID{
######################################################################
# This private method returns a boolean to indicate whether the cdt file
# has an GID column

    return $_[0]->{$kHasGID};

}

######################################################################
sub _parseFileHeaders{
######################################################################
# This private method removes the file headers from a cdt file.  It
# accepts a file handle as input, and assumes that the file handle is
# pointing to the very beginning of the file.

    my ($self, $fh) = @_;

    my $line = <$fh>;

    if (!exists($self->{$kIdName})){ # if we've not read this line before

	my $lineRef = $self->_arrayRefForLine(\$line);

	$self->__parseFirstLine($lineRef);

    }

    if ($self->__hasAID){ # need to parse out the AID line
	
	$line = <$fh>;

	if (!exists $self->{$kAIDs}){ # the second line has the AIDs
	
	    my $lineRef = $self->_arrayRefForLine(\$line);

	    $self->__parseSecondLine($lineRef);

	}
	
    }

    # now set the data line row count to zero, as the next line
    # to be read in will be the first data line

    $self->_setCurrFileDataRow(0);    

}

######################################################################
sub __parseFirstLine{
######################################################################
# This method deals with recording data from the first line of a cdt
# file.  It accepts as input a reference to an array that contains
# the fields on the first line split on tabs.

    my ($self, $lineRef) = @_;

    shift @{$lineRef} if ($self->__hasGID);
    
    $self->idName  (shift @{$lineRef});
    $self->descName(shift @{$lineRef});
    
    if (shift @{$lineRef} ne "GWEIGHT"){
	
	$self->__usage("Your file, ".$self->file." has no GWEIGHT column header");
	
    }
	    
    $self->columnNamesArrayRef($lineRef);

}

######################################################################
sub __parseSecondLine{
######################################################################
# This method deals with recording data from the second line of a cdt
# file.  It accepts as input a reference to an array that contains
# the fields on the second line split on tabs.
    
    my ($self, $lineRef) = @_;

    # this subroutine deals with parsing out the AID line.
    # it will die if the line passed in is not an AID line.

    die "A non-AID line was passed into __parseSecondLine()" if ($lineRef->[0] ne "AID");

    if ($self->__hasGID){ # there's a gid column to remove

	shift @{$lineRef};

    }

    # now simply store the array clustering information

    $self->AIDsArrayRef([@{$lineRef}[3..$#$lineRef]]); # anonymous array reference

}

######################################################################
sub _removeMetaDataFromLine{
######################################################################
# This method removes and stores meta data from a data line in a cdt file.
# Because the array of data is passed in by reference, the array to which
# this reference refers is directly manipulated, such that the caller's
# array will have meta data removed from it

    my ($self, $currFileDataRow, $lineRef) = @_;

    if ($self->_metaDataRecorded($currFileDataRow)){

	# if we've already recorded the meta data for this line number,
	# simply remove the data from the line

	shift @{$lineRef} if ($self->__hasGID); # remove extra column if we have GID column

	shift @{$lineRef}; shift @{$lineRef}; shift @{$lineRef}; 
	
    }else{ 

	# otherwise record the data, and then remember that we've recorded it

	$self->GID($currFileDataRow, shift @{$lineRef}) if ($self->__hasGID);

	$self->rowName($currFileDataRow, shift @{$lineRef});
	$self->rowDesc($currFileDataRow, shift @{$lineRef});
	$self->gWeight($currFileDataRow, shift @{$lineRef});
	
	$self->_indicateMetaDataRecorded($currFileDataRow);

    }
	
}

######################################################################
sub GID{
######################################################################
# This polymorphic setter/getter method returns the GID value for a given
# row in the cdt file.  If a new GID is provided, it will update that
# name to the new value.  Note the row number that is passed in is based
# on the row number in the file used for object construction.
#
# Usage:
#
# $self->GID($rowNum, $newGID);
#
# my $gid = $self->GID($rowNum);
    
    my ($self, $rowNum, $data) = @_;
    
    defined ($data) && ($self->{$kGIDs}->[$rowNum] = $data);
    
    return $self->{$kGIDs}->[$rowNum];
    
}


######################################################################
sub rowName{
######################################################################
# This polymorphic setter/getter method returns the row name for a given
# row in the cdt file.  If a new name is provided, it will update that
# name to the new value.  Note the row number that is passed in is based
# on the row number in the file used for object construction.
#
# Usage:
#
# $self->rowName($rowNum, $newName);
#
# my $rowName = $self->rowName($rowNum);
    
    my ($self, $rowNum, $data) = @_;
    
    defined ($data) && ($self->{$kRowNames}->[$rowNum] = $data);
    
    return $self->{$kRowNames}->[$rowNum];
    
}

######################################################################
sub rowDesc{
######################################################################
# This polymorphic setter/getter method returns the row description
# for a given row in the cdt file.  If a new description is provided,
# it will update that description to the new value.  Note the row
# number that is passed in is based on the row number in the file used
# for object construction.
#
# Usage:
#
# $self->rowDesc($rowNum, $newDesc);
#
# my $rowDesc = $self->rowDesc($rowNum);

    my ($self, $rowNum, $data) = @_;

    defined ($data) && ($self->{$kRowDescs}->[$rowNum] = $data);

    return $self->{$kRowDescs}->[$rowNum];

}

######################################################################
sub gWeight{
######################################################################
# This polymorphic setter/getter method returns the gWeight for a
# given row in the cdt file.  If a new gWeight is provided, it will
# update that gWeight to the new value.  Note the row number that is
# passed in is based on the row number in the file used for object
# construction.
#
# Usage:
#
# $self->gWeight($rowNum, $newGWeight);
#
# my $gWeight = $self->gWeight($rowNum);

    my ($self, $rowNum, $data) = @_;

    defined ($data) && ($self->{$kgWeights}->[$rowNum] = $data);

    return $self->{$kgWeights}->[$rowNum];

}

######################################################################
sub AIDsArrayRef{
######################################################################
# This polymorphic setter/getter method returns a reference to an
# array of the AIDs that existed in the original file, in the
# order that they appeared.  If a new array reference is provided, it
# will give the experiments new AIDs.
#
# Usage:
#
# my $AIDsArrayRef = $self->AIDsArrayRef; 
# $self->AIDsArrayRef(\@AIDs);

    my ($self, $data) = @_;

    defined ($data) && ($self->{$kAIDs} = $data);

    return $self->{$kAIDs};

}

######################################################################
sub idName{
######################################################################
# This polymorphic setter/getter method returns the name of the id
# column that was used in the original file.  If a new value is passed
# in, it will instead use that value as the id column name.
#
# Usage:
#
# print $self->idName;
# $self->idName($idName);

    my ($self, $data) = @_;

    defined ($data) && ($self->{$kIdName} = $data);

    return $self->{$kIdName};

}

######################################################################
sub descName{
######################################################################
# This method returns the name of the description column that was used
# in the original file

    my ($self, $data) = @_;

    defined ($data) && ($self->{$kDescName} = $data);

    return $_[0]->{$kDescName};

}


######################################################################
sub _printLeadingMeta{
######################################################################
# This method prints the first two lines of a cdt file out.
#
# Usage : $self->_printLeadingMeta($fh, $validColumnsArrayRef, $hasExtraInfo, $extraInfoName);
#
# This method prints to the passed in file handle.  It will only print
# meta information for those valid columns.  If the $extraInfo
# variable is true (ie a non-zero value) it will leave a print a
# column called $extraInfoName in between each column of meta data.

    my ($self, $fh, $validColumnsArrayRef, $hasExtraInfo, $extraInfoName) = @_;

    # print the experiment names line

    if ($self->__hasGID){

	print $fh "GID\t";

    }

    print $fh $self->idName, "\t", $self->descName, "\tGWEIGHT";

    my $columnNamesArrayRef = $self->columnNamesArrayRef;

    foreach my $column (sort {$a <=> $b } @{$validColumnsArrayRef}){

	print $fh "\t", $columnNamesArrayRef->[$column];

	$hasExtraInfo && print($fh "\t$extraInfoName");

    }

    print $fh "\n";

    # now print the AID line, if there is one

    if ($self->__hasAID){

	print $fh "AID\t\t";

	if ($self->__hasGID){

	    print $fh "\t"; # need an extra column

	}

	my $AIDsArrayRef = $self->AIDsArrayRef;

	foreach my $column (sort {$a <=> $b } @{$validColumnsArrayRef}){

	    print $fh "\t", $AIDsArrayRef->[$column];

	    $hasExtraInfo && print($fh "\t");

	}

	print $fh "\n";

    }

}

######################################################################
sub _printRowMetaData{
######################################################################
# This method (required by the tabDelimitedDataMatrix) prints out the
# meta data for a single row, to a passed in file handle
#
# Usage : $self->_printRowMetaData($fh, $row);

    my ($self, $fh, $row) = @_;
    
    if ($self->__hasGID){

	print $fh $self->GID($row), "\t";

    }

    print $fh $self->rowName($row), "\t", $self->rowDesc($row), "\t", $self->gWeight($row);
    
}

sub _printTrailingMeta{

    # nothing needs to be done
    
}

######################################################################
sub convertToPcl{
######################################################################
# This method will create a pclFile from a cdtFile.  It will do this
# by stripping out the GID column, and the AID row.  It will also add
# in an EWEIGHTs row.  It must be given the name of the file that
# should be created.  If no .pcl extension is given, one will be added
#
# Usage : $cdtFile->convertToPcl($file);

    my ($self, $file) = @_;

    my $hasGID = $self->__hasGID;
    my $hasAID = $self->__hasAID;

    $self->__setHasGID(0); # so they get stripped out when printing
    $self->__setHasAID(0);

    my $validColumnsArrayRef = $self->_validColumnsArrayRef;

    if ($file !~ /\.pcl$/){

	$file .= ".pcl";

    }

    open (PCL, ">$file") || die "Cannot open $file : $!\n";

    $self->_printLeadingMeta(\*PCL, $validColumnsArrayRef);

    print PCL "EWEIGHT\t\t";

    foreach (@{$validColumnsArrayRef}){

	print PCL "\t1";

    }

    print PCL "\n";

    foreach my $row (sort {$a<=>$b} @{$self->_validRowsArrayRef}){

	$self->__setHasGID($hasGID); # so getting the data works correctly
	$self->__setHasAID($hasAID);

	my $dataRef = $self->_dataLine($row); # get the data

	$self->__setHasGID(0); # now set to zero so printing works correctly
	$self->__setHasAID(0);

	# now print it out, with no GID or AID

	$self->_printRow(\*PCL, $row, $dataRef, $validColumnsArrayRef);

    }

    $self->__setHasGID($hasGID); # now reset back to previous state
    $self->__setHasAID($hasAID);

    close PCL;

}
	


1; # to keep perl happy

=pod

=head1 NAME

Microarray::DataMatrix::CdtFile - abstraction to cdtfile

=head1 Abstract

cdtFile.pm provides an abstraction layer to a cdt file, in that
it provides methods for manipulating or querying the contents of a
cdt file.

=head1 Overall Logic

This is for programmers only - do not rely on any of these details
when programming clients of the object, as the underlying implementation
is subject to change at any time without notice.

The cdtFile does little more than providing the parsing ability for
cdt files.  All filtering/transformations are taken care of by
anyDataMatrix, from which it inherits.

=head1 Public Methods

=head2 new

Constructor - will take a fully qualified filename that correspond to
a cdt file as a name argument - see -
http://genome-www5.stanford.edu/MicroArray/help/formats.shtml.  In
addition you can set a variable, autodump, to indicate whether data
should be automatically dumped out after any method call that
transforms or filters the data.  If this is not set, then you must
manually call the dumpData method.  The default is for autodumping to
be off.  This is useful, for instance, because you may run several
filters/transformations over the data, and only want to dump the data
at the end, which is more optimal that dumping it at every step.  Note
that if autodumping is on, then the data are only dumped if a method
completes successfully.  Currently, if a method fails, the matrix may
be left in an uncertain state, and should not be used further.

Construction requires that a directory be provided where temp files
may be written, which may be generated during matrix filtering and
transformation.

Usage:

	my $cdtFile = cdtFile->new(file=>$file,
		                   autodump=>1,
	                           tmpDir=>$tmpDir);

returns : a cdtFile object.

=head2 dumpData 

This method dumps the current contents of the cdtFile object to a
file, either whose name was provided as a single argument, or to a
file whose name was used to construct the object.  If the data have
been filtered based on columnPercentiles, and these were elected to be
shown, then these will be dumped out too (see below).

Usage:

    $cdtFile->dumpData($file);

or:

    $cdtFile->dumpData;

=head1 Tranformation and Filtering Methods

General note on methods that transform the data : If autodumping is
on, then by default, they will overwrite the file that was used to
create the cdtFile object, unless a new filename is passed in.  If
a new filename is passed in (as an argument named 'file'), and
autodumping is on, then further operations on the cdtFile of
filtered data will require instantiation of a cdtFile object with
that file.  Note, this also means that the program MUST have
permissions to overwrite the file, and also to write to the same
directory as the file (for temp file purposes).

All of the transformation and filtering methods return 1 upon success.
If an error was encountered, then the method will return 0, and the
error message associated with the problem can be retrieved using the
errstr() method, eg:

      $cdtFile->methodX(%args) || die "An error occured ".$cdtFile->errstr."\n";

All of the transformation and filtering methods allow a verbose
argument to be passed in, with valid values for the verbose argument
being either 'text' or 'html'.  For text, \n will be used as an end of
line character after every line of reporting is printed.  For html,
\n<br> will be used, eg:

      $cdtFile->center(rows=>'mean',
		       verbose=>'html') || die $cdtFile->errstr;

=head2 center

This method allows either rows or columns of the cdtFile to be
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

	$cdtFile->center(rows=>'mean',
			    columns=>'median') || die $cdtFile->errstr;


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

	$cdtFile->filterByPercentPresentData(rows=>80,
                                                columns=>80);

	$cdtFile->filterByPercentPresentData(rows=>90,
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

Usage:

	$cdtFile->filterRowsOnColumnPercentile(percentile=>95,
                                                  numColumns=>1,
						  showPercentiles=>1);


returns : 1 upon success, or 0 otherwise

=head2 filterRowsOnColumnDeviation

This method will filter out rows whose values do not deviate from the
column mean by a specified number of standard deviations, in at least
numColumns columns.

Usage:

	$cdtFile->filterRowsOnColumnDeviation(deviations=>2,
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

	$cdtFile->filterRowsOnValues(operator=>"absolute value >",
					value=>2,
					numColumns=>1);


returns : 1 upon success, or 0 otherwise

=head2 filterRowsOnVectorLength

This method filters out rows based on whether the vector that their
values define has a length of greater than the specified length.

Usage:

	$cdtFile->filterRowsOnVectorLength(length=>2);

returns : 1 upon success, or 0 otherwise

=head2 logTransformData

This method log transforms the contents of the data matrix, using the
specified base.  If any values less than or equal to zero are
encountered, then the transformation will fail.  The matrix will be
returned to its state prior to log transformation if the operation
fails.

Usage :

    $cdtFile->logTransformData(base=>2);

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

    $cdtFile->scaleColumnData(columns=>{0=>1.2,
					   2=>0.8});

returns : 1 upon success, or 0 otherwise

=head1 Public Accessor Methods

=head2 file

This methods returns the name of the file that was used to construct
the object.

Usage:

	my $file = $cdtFile->file;

returns: a scalar

=head2 numRows

This method returns the number of rows that are currently valid in the
data matrix.

Usage:

	my $numRows = $cdtFile->numRows;

returns: a scalar

=head2 numColumns

This method returns the number of columns that are currently valid in
the data matrix.

Usage:

	my $numColumns = $cdtFile->numColumns;

returns: a scalar

=head2 errstr

This method returns an error string that is associated with the last
failed call to a data transformation/filtering method.  Calling this
method will clear the contents of the error string.

=head1 Public Setter Methods

=head2 setAutoDump

This method can be used to turn autodumping on or off.

Usage:

    $cdtFile->setAutoDump($n); # where $n can be 0 or 1

=head1 Public setter/getter methods

=head2 rowName

This polymorphic setter/getter method returns the row name for a given
row in the cdt file.  If a new name is provided, it will update that
name to the new value.  Note the row number that is passed in is based
on the row number in the file used for object construction.

Usage:

    $self->rowName($rowNum, $newName);

    my $rowName = $self->rowName($rowNum);

=head2 rowDesc

This polymorphic setter/getter method returns the row description for
a given row in the cdt file.  If a new description is provided, it
will update that description to the new value.  Note the row number
that is passed in is based on the row number in the file used for
object construction.

Usage:

    $self->rowDesc($rowNum, $newDesc);

    my $rowDesc = $self->rowDesc($rowNum);

=head2 gWeight

This polymorphic setter/getter method returns the gWeight for a given
row in the cdt file.  If a new gWeight is provided, it will update
that gWeight to the new value.  Note the row number that is passed in
is based on the row number in the file used for object construction.

Usage:

    $self->gWeight($rowNum, $newGWeight);

    my $gWeight = $self->gWeight($rowNum);

=head2 eweightsArrayRef

This polymorphic setter/getter method returns a reference to an array
of the eweights that existed in the original file, in the order that
they appeared.  If a new array reference is provided, it will give the
experiments new eweights.

Usage:

    my $eweightsArrayRef = $self->eweightsArrayRef; 
    $self->eweightsArrayRef(\@eweights);

=head2 idName

This polymorphic setter/getter method returns the name of the id
column that was used in the original file.  If a new value is passed
in, it will instead use that value as the id column name.

Usage:

    print $self->idName;
    $self->idName($idName);

=head2 descName

This polymorphic setter/getter method either returns the name of the
description column that was used in the original file, or allows it to
be set to a new value.

Usage:

    print $self->descName;
    $self->descName($descName);

=head1 Protected methods

=head2 _printLeadingMeta

This method prints the first two lines of a cdt file out.  It prints
to the passed in file handle.  It will only print meta information for
those valid columns.  If the $extraInfo variable is true (ie a
non-zero value) it will leave a print a column called $extraInfoName
in between each column of meta data.  This method is implemented as
required by its superclass, anySizeDataMatrix.

Usage:

    $self->_printLeadingMeta($fh, $validColumnsArrayRef, $hasExtraInfo, $extraInfoName);

=head2 _printTrailingMeta

This method is implemented as required by its superclass,
anySizeDataMatrix.  For a cdtFile, it down;t actually need to do
anything.

Usage:

    $self->_printTrailingMeta($fh, $self->_validColumnsArrayRef);

=head1 Private Methods

=head2 __usage

This private method prints out a usage message for the constructor,
and then dies with a specific error message.

Usage : 

    $self->__usage("$file does not exist");

=head2 _parseFileHeaders

This private method removes the file headers from a cdt file.  It
accepts a file handle as input, and assumes that the file handle is
pointing to the very beginning of the file.

Usage:

    $self->_parseFileHeaders($fh);

=head2 __parseFirstLine

This method deals with recording data from the first line of a cdt
file.  It accepts as input a reference to an array that contains the
fields on the first line split on tabs.

Usage:

    $self->__parseFirstLine($lineRef);

=head2 __parseSecondLine

This method deals with recording data from the second line of a cdt
file.  It accepts as input a reference to an array that contains the
fields on the first second split on tabs.

Usage:

    $self->__parseSecondLine($lineRef);

=head2 _removeMetaDataFromLine

This method removes and stores meta data from a data line in a cdt
file.  Because the array of data is passed in by reference, the array
to which this reference refers is directly manipulated, such that the
callers array will have meta data removed from it.

Usage:

    $self->_removeMetaDataFromLine($currFileDataRow, $lineRef);

=head1 AUTHOR

Gavin Sherlock

sherlock@genome.stanford.edu

=cut

