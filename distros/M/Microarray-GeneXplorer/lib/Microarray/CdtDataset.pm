package Microarray::CdtDataset;

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


# Author : Gavin Sherlock (based on Christian Rees' dataset object)
# Date   : 14th August 2002

# Re-visited by John Matese, under auspices of the GMOD project
# Date   : 28th May 2003

# Description: This package implements an object that serves as an
# abstraction to a cdtDataset.  It is different than the
# Microarray::DataMatrix::CdtFile abstraction, because it deals with
# the cdtFile in the context of gtr and/or atr files.  It also
# provides methods by which the geneXplorer program can interact with
# a cdtDataset.
#    The essential purpose of CdtDataset's initialization functions is to
# de-construct the .cdt file into its constituent data parts of the
# dataset:
#    1) the data matrix (.data_matrix)
#    2) the bioassay names or slidenames (.expt_info)
#    3) the annotations of the spotted features/reporters/sequences
#       (.feature_info)
#    4) any additional meta information about the set (.meta)
#    5) additionally, it computes or creates the following:
#        a) a binary file containing a list of feature-feature
#           correlations (.binCor) 
#        b) a 2-color image representation of the data matrix
#           (.data_matrix.png)
#        c) a image representation of the expt_info file
#           (.expt_info.png)
#
# Known Issues: There are good reasons to add additional meta data to
# a dataset, including possibly the organism of the set or the
# location of the default display configuration file to display the 
# .feature_info. These would probably have to be called in the constructor.
#
#
# Note: there are many vestiges of code left over from previous
# developers.  These could be viewed as either an emergent/embryonic
# API or alternatively as vestigial limbs needing to be lopped off.
# i.e. the need for these methods/accessors existed at some time in
# the past, and may indeed be resurrected in the future.  Currently,
# they are not supported.
#
#
# Future Plans: Currently, only the .cdt file of a clustered dataset
# is utilized.  In the future, the other data files detailing the
# clustering [gene tree(.gtr) and array tree(.atr)] should be
# utilized, and DatasetImageMaker should export suitable image
# representations for these files.  Furthermore, It would be great to
# pull general dataset methods from this class into a future class,
# Microarray::Dataset.  That way, you could make a MageMLDataset class
# as well, and still keep many of the general class attributes/methods
# in the same locations.  Microarray:Dataset would inherit constructor
# methods (i.e. knowledge of the file structure) from either
# CdtDataset orMageMLDataset at initialization (perhaps a run-time ISA
# declaration within the constructor).  Otherwise, I don't see a huge
# advantage to having these specialized (and somewhat misnamed)
# classes, in the sense that Dataset only need to know how to parse
# the initialization file while convertind a new dataset



use strict;
use GD;
use File::Basename;

use Microarray::Config;
use Microarray::DatasetImageMaker;
use Microarray::Utilities::Filesystem qw(DirectoryIsValid EnsureTrailingSlash);
use Microarray::DataMatrix::CdtFile;
use Microarray::DataMatrix::PclFile;


my $dbg = 0;

my $VERSION = "0.1";

my $PACKAGE = 'Microarray::CdtDataset';

my $kCdtBase = $PACKAGE.'::__cdtBase';
my $kCdtPath = $PACKAGE.'::__cdtPath';


my $kName             = $PACKAGE.'::__name'; # the full qualified name of the dataset
my $kFileBaseName     = $PACKAGE.'::__fileBaseName'; # the stem of the file names (for dataset)

my $kDataPath         = $PACKAGE.'::__dataPath';
my $kImagePath        = $PACKAGE.'::__imagePath';
my $kContrast         = $PACKAGE.'::__contrast';
my $kShouldInitialize = $PACKAGE.'::__shouldInitialize';
my $kCdtFileObject    = $PACKAGE.'::__cdtFileObject';
my $kCdtFileName      = $PACKAGE.'::__cdtFileName';
my $kHeight           = $PACKAGE.'::__height';
my $kWidth            = $PACKAGE.'::__width';
my $kColorScheme      = $PACKAGE.'::__colorscheme';
my $kConfig           = $PACKAGE.'::__config';
my $kCorrCutoff       = $PACKAGE.'::__corrCutoff';

my $kDefaultContrast       = 4;
my $kDefaultInitialization = 0;
my $kDefaultCorrCutoff     = 0.5;
my $kDefaultColorScheme    = 'yb'; # yellow/blue

my $kMinCorrCutoff   = 0.2;

my $kImgType = Microarray::Config->ImageType;

my @metaColumns = ($kWidth, $kHeight, $kContrast, $kColorScheme, $kCorrCutoff);

my %kColorSchemeTranslation = Microarray::Config->ColorSchemeTranslationHash;

my $kCdtSuffix       = '.cdt';
my $kMetaSuffix      = '.meta';
my $kLockSuffix      = '.lock';
my $kFeatureSuffix   = '.feature_info';
my $kMatrixSuffix    = '.data_matrix';
my $kExptInfoSuffix  = '.expt_info';
my $kPclSuffix       = '.pcl';
my $kStdCorrSuffix   = '.stdCor';
my $kBinCorrSuffix   = '.binCor';

my $kInfoGifSuffix   = $kExptInfoSuffix.'.'.$kImgType; 
my $kMatrixGifSuffix = $kMatrixSuffix.'.'.$kImgType;

my @kRequiredFileSuffixes = (
# cdt not required, unless we start copying it there
#			     $kCdtSuffix, 
			     $kMetaSuffix, 
			     $kFeatureSuffix,
			     $kMatrixSuffix, 
			     $kExptInfoSuffix, 
			     $kBinCorrSuffix
# images may reside in a different directory than the data, should fix this
#			     $kInfoGifSuffix,
#			     $kMatrixGifSuffix
			     );


####################################################################
sub new {
####################################################################
# This is the constructor.  There are two modes in which the
# constructor can be used.  In one mode, it will create various files
# which support the dataset, using the cdt, (and hopefully in the
# future, gtr and atr files).  In the second mode, it will assume that
# these files already exist and just return the constructed objevt.
# Thus when a dataset is first created, there will be the overhead of
# creating the additional files, but subsequent creation of a
# cdtDataset object will not have that overhead.  The constructor
# takes the following arguments:
#
# name         :  The fully qualified name of the dataset (slash/delimited),
#                 which encodes the location and stem of the files,
#                 without any extensions, and with no path
#                 information. If the 'initialize' argument is set
#                 (see below), a directory tructure of the same name
#                 will also be created to contain the exported data
#                 files.
#
# datapath     :  This required path prefix is where any newly created data
#                 files should be placed (or read from).
#
# imagepath    :  An optional path prefix where any newly created image files
#                 should be placed (or read from). Will default to
#                 datapath if none is specified.
#
# contrast     :  If a dataset is being instantiated for the first
#                 time, then a contrast is needed for image
#                 generation.  If no contrast is provided, then a
#		  default value of 4 will be used.  As the data are
#		  expected to be in log base 2, this corresponds to a
#		  16-fold change as the maximum color in any image.
#
# colorscheme  :  Can either be 'red/green' (the default if none is
#                 specified) or 'yellow/blue'
#
# corrcutoff   :  If a dataset is initiated for the first time, correlation
#                 values are generated for each feature-pair and values
#                 above the cutoff are saved in a binary .binCor file
#
# initialize   :  A filepath of the originating .cdt file indicate
#                 whether to initialize all the required supporting
#                 files that a cdtDataset needs.  This defaults to 0
#                 (assumes that the necessary supporting files already
#                 exist.  If it is a filepath, then the dataset is
#                 initialized using it
#
#
# Note that if you supply a contrast, you must set initialize to 1, as
# a contrast is useless in the absence of initialization.  Both the
# 'dataset' and 'path' arguments are absolutely required.
#
# Usage, eg if you have a file:
#
#    my $ds = Microarray::CdtDataset->new(name=>dataset/name, # name of the dataset
#					  datapath=>$dir,     # prefix path where dataset files will be written
#					  contrast=>2,        # image contrast
#					  initialize=>/path/to/file.cdt);


    my $class = shift;
    my $self  = { };

    bless ($self, $class);

    eval {
	$self->__init(@_);
    };

    if ($@) { 
	die "The following error occurred: $@\n";
    };

    return $self;
}

############################################################################
sub __init{
############################################################################
# This method takes care of all of the initialization of the
# attributes of the cdtDataset

    my $self = shift;

    $self->__checkAndSetConstructorArguments(@_);

    if ($self->__shouldInitialize){

	$self->__initializeDataset;

	$self->__setShouldInitialize(0); # so we know it's done

    }else{

	$self->__checkRequiredFilesExist;

	# we need to load some meta information instead
	$self->_load_meta;

    }

    # now load all the required feature and experiment info into
    # memory

    $self->__loadExptInfo;
    $self->__loadFeatureInfo;

}

############################################################################
sub __checkAndSetConstructorArguments{
############################################################################
# This private method checks that the constructor arguments pass all
# sanity checks, and that files that should exist do exist.

    my ($self, %args) = @_;

    $self->__checkAndSetInitializationState(%args);
    $self->__checkAndSetConfig(%args);
    $self->__checkAndSetDataPath(%args);
    $self->__checkAndSetImagePath(%args);
    $self->__checkAndSetDatasetName(%args);
    $self->__checkAndSetContrast(%args);
    $self->__checkAndSetColorScheme(%args);
    $self->__checkAndSetCorrCutoff(%args);

}


############################################################################
sub __checkAndSetInitializationState{
############################################################################
# This method checks and sets whether the object needs full
# initialization.  There are meant to be 2 initilization requests.
# The first (initialization=><path>) would request that the dataset be
# created de novo from an initial file, and the second
# (initialization=>1) would just remake the images with a different
# constrast and different colors.  The second initialization has not
# been adequately tested.

    my ($self, %args) = @_;    
    
    if (exists($args{'initialize'})){

	# the argument must be a cdt file path or a boolean
	if (-e $args{'initialize'}){

	    if (!-r $args{'initialize'}){
	
		die "The cdt file for initialization, $args{'initialize'}, is not readable.";
	
	    }elsif (!-T $args{'initialize'}){
	
		die "The cdt file for initialization, $args{'initialize'}, is not a text file.";

	    }

	    $self->__setCdtFileName($args{'initialize'});
	    $self->__setShouldInitialize(1);

	}elsif ($args{'initialize'} == 1){

	    # this should signify that the caller wants to re-make the
	    # images only, based on a pre-exisiting dataset.  JCM
	    # note: This probably has not been thoroughly tested! (no
	    # explicit client available (though easy to modify
	    # bin/makeMicroarrayDataset), and change of constructor
	    # API has occurred)

	    $self->__setShouldInitialize(1);

	}else {

	    die "The 'initialize' argument must be equal to 1 or be a valid $kCdtSuffix filepath.  \nA value of '$args{'initialize'}' was supplied\n";
	}

    }else{

	$self->__setShouldInitialize($kDefaultInitialization); # set default

    }
}

############################################################################
sub __checkAndSetConfig{
############################################################################
# This private method checks and stores the config object that should
# be passed in

    my ($self, %args) = @_;

    if (exists($args{'config'})){

	if ($args{'config'}->isa("Microarray::Config")){

	    $self->{$kConfig} = $args{'config'};

	}else{

	    die "The 'config' argument you provided is not a Microarray::Config object.";

	}

    }else{

	die "A 'config' argument was not supplied to the ".ref($self)." constructor.";

    }

}

############################################################################
sub __checkAndSetDataPath{
############################################################################
# This private method checks that an Path is supplied, that
# corresponds to an existent directory, then stores it in the object.

    my ($self, %args) = @_;

    if (exists($args{'datapath'})){

	# check that it's good

	unless (&DirectoryIsValid($args{'datapath'})) {

	    die "The supplied 'datapath', $args{'datapath'}, either does not exist or is not a directory.";

	}

	# fix up the Path so it has a trailing forward slash
	$args{'datapath'} = &EnsureTrailingSlash($args{'datapath'});

    }else{

	die "A 'datapath' argument was not supplied to the ".ref($self)." constructor.";
	
    }

    $self->__setDataPath($args{'datapath'});

}


############################################################################
sub __checkAndSetImagePath{
############################################################################
# This private method checks that an Path is supplied, that
# corresponds to an existent directory, then stores it in the object.

    my ($self, %args) = @_;

    if (exists($args{'imagepath'})){

	# check it's good

		unless (&DirectoryIsValid($args{'imagepath'})) {

	    die "The supplied 'imagepath', $args{'imagepath'}, either does not exist or is not a directory.";

	}

	# fix up the Path so it has a trailing forward slash
	$args{'imagepath'} = &EnsureTrailingSlash($args{'imagepath'});

    }else{

	# use datapath as the default (generic module)
	$args{'imagepath'} = $self->datapath;

    }

    $self->__setImagePath($args{'imagepath'});

}


############################################################################
sub __checkAndSetDatasetName{
############################################################################
# This method checks that a dataset was given to the constructor.  In
# addition because CdtDataset creates and stores all its images and
# data in a directory hierarchy, the initially specified data and
# image paths are augmented with the dataset name directories (which
# are created upon initialization)

    my ($self, %args) = @_;

    # check we have a good name

    if (!exists($args{'name'})){

	die "The required 'name' argument was not supplied to the ".ref($self)." constructor.";

    }

    my $fullPathToData = &EnsureTrailingSlash($self->datapath.$args{'name'});
    my $fullPathToImages = &EnsureTrailingSlash($self->imagepath.$args{'name'});

    if ($self->__shouldInitialize) { # make them if initialization was requested

	$self->__setDataPath($self->__ensureDirectoriesExist($self->datapath, $args{'name'}));
	$self->__setImagePath($self->__ensureDirectoriesExist($self->imagepath, $args{'name'}));


    }else{ # make certain the dataset is where they said it is

	&DirectoryIsValid($fullPathToData) || die "Could not validate dataset directories (datapath + dataset name) residence at $fullPathToData.\n";

	&DirectoryIsValid($fullPathToImages) || die "Could not validate dataset image directories (image path + dataset name) residence at $fullPathToImages.\n";


    }

    my $datasetBase = basename($args{'name'});

    $self->__setDataPath($fullPathToData); # augmenting datapath with data set directory name
    $self->__setImagePath($fullPathToImages); # augmenting imagepath with data set directory name
    $self->__setDatasetName($args{'name'});
    $self->__setFileBaseName($datasetBase);

}



############################################################################
sub __checkAndSetContrast{
############################################################################
# This method determines if the contrast is valid, and then stores the
# value in the object

    my ($self, %args) = @_;

    if (exists($args{'contrast'})){
	
	if (!exists($args{'initialize'})){
	    
	    die "A 'contrast' argument was provided to the ".ref($self)." constructor, but an initialize argument was not.";
	    
	}elsif ($args{'contrast'} <= 0){
	    
	    die "The supplied value for the 'contrast' argument must be greater than zero.  A value of $args{'contrast'} was supplied.";
	    
	}
	
	$self->__setContrast($args{'contrast'});
	
    }else{

	$self->__setContrast($kDefaultContrast); # set the default

    }

}

############################################################################
sub __checkAndSetColorScheme{
############################################################################
# This method determines if the colorscheme is valid, and then stores
# the value in the object

    my ($self, %args) = @_;

    if (exists($args{'colorscheme'})){
	
	if (!exists($args{'initialize'})){
	    
	    die "A 'colorscheme' argument was provided to the ".ref($self)." constructor, but an initialize argument was not.";
	    
	}elsif (!exists($kColorSchemeTranslation{$args{'colorscheme'}})){
	    
	    die "The supplied value for the 'colorscheme' argument must be one of \n\n".
		join("\n", keys %kColorSchemeTranslation)."\n\nA value of $args{'colorscheme'} was supplied.";
	    
	}
	
	$self->__setColorScheme(($kColorSchemeTranslation{$args{'colorscheme'}}));
	
    }else{

	$self->__setColorScheme($kDefaultColorScheme); # set the default

    }

}

############################################################################
sub __checkAndSetCorrCutoff{
############################################################################
# This method determines if the correlation cutoff value is valid, and then stores
# the value in the object

    my ($self, %args) = @_;

    if (exists($args{'corrcutoff'})){
	
	if (!exists($args{'initialize'})){
	    
	    die "A 'corrcutoff' argument was provided to the ".ref($self)." constructor, but an initialize argument was not.";
	    
	}elsif ($args{'corrcutoff'} !~ /^[\d\.]+$/g  
		|| $args{'corrcutoff'} > 1 
		|| $args{'corrcutoff'} < $kMinCorrCutoff){
	    
	    die "The supplied value for the 'corrcutoff' argument must be a number \n\n".
		"$kMinCorrCutoff  =<  corrcutoff  =<  1"."\n\nA value of $args{'corrcutoff'} was supplied.";
	}
	
	$self->__setCorrCutoff($args{'corrcutoff'});
	
    }else{

	$self->__setCorrCutoff($kDefaultCorrCutoff); # set the default

    }

}


#####################################################################
sub __checkRequiredFilesExist{
#####################################################################
# This method checks that all the required files for the dataset exist
# If they do not, it will cause a fatal error

    my $self = shift;

    my $prefix = $self->datapath;
    $prefix = &EnsureTrailingSlash($prefix);

    $prefix .= $self->fileBaseName;

    foreach my $suffix (@kRequiredFileSuffixes){

	die $prefix.$suffix." does not exist." if (!-e $prefix.$suffix);

    }
}


############################################################################
sub __setCdtInfo {
############################################################################
# this subroutine takes the initalize arguement and store the path and
# the stem of the .cdt filename

    my ($self, $filepath);

    my ($base, $inpath, $suffix) = fileparse($filepath, $kCdtSuffix);
    $self->{$kCdtBase} = $base;
    $self->{$kCdtPath} = $inpath;


}



#####################################################################
sub __setFileBaseName {
#####################################################################
# This method allows the filename stem (no suffix) of the datafiles
# use to initialize the dataset to be set

    my ($self, $nameBase) = @_;
    $self->{$kFileBaseName} = $nameBase;
}


#####################################################################
sub __setDataPath {
#####################################################################
# This method allows the path to where the data files for the dataset
# exist to be set

    my ($self, $outpath) = @_;
    $self->{$kDataPath} = $outpath;
}


#####################################################################
sub __setImagePath {
#####################################################################
# This method allows the path to where the image files for the dataset
# exist to be set

    my ($self, $outpath) = @_;
    $self->{$kImagePath} = $outpath;
}


#####################################################################
sub __setDatasetName {
#####################################################################
# This method allows the name of the dataset to be set.

    my ($self, $datasetName) = @_;
    $dbg && print "\t dataset name $datasetName \n";
    $self->{$kName} = $datasetName;
}


#####################################################################
sub __setCdtFileName  {
#####################################################################
# This method sets the name of the cdtFile

    my ($self, $cdtFile) = @_;
    $self->{$kCdtFileName} = $cdtFile;
}


#####################################################################
sub __setContrast {
#####################################################################
# This method allows the contrast to be set.

    my ($self, $contrast) = @_;
    $self->{$kContrast} = $contrast;
}


#####################################################################
sub __setColorScheme {
#####################################################################
# This method allows the colorscheme to be set.

    my ($self, $colorScheme) = @_;
    $self->{$kColorScheme} = $colorScheme;
}


#####################################################################
sub __setCorrCutoff {
#####################################################################
# This method allows the correaltion cutoff to be set.

    my ($self, $corrCutoff) = @_;
    $self->{$kCorrCutoff} = $corrCutoff;
}


#####################################################################
sub __setShouldInitialize {
#####################################################################
# This method allows a flag to be set as to whether full
# initialization need to take place

    my ($self, $shouldInitialize) = @_;
    $self->{$kShouldInitialize} = $shouldInitialize;
}


#####################################################################
sub __setHeight {
#####################################################################
# This private method allows the 'height' of the dataset to be set.
# This in fact corresponds to the number of rows in the cdt file.

    my ($self, $height) = @_;
    $self->{$kHeight} = $height;
}


#####################################################################
sub __setWidth {
#####################################################################
# This private method allows the 'height' of the dataset to be set.
# This in fact corresponds to the number of rows in the cdt file.

    my ($self, $width) = @_;
    $self->{$kWidth} = $width;
}


#####################################################################
sub name {
#####################################################################
# This method returns the fully qualified name of the dataset

    return $_[0]->{$kName};
}


#####################################################################
sub _cdtFileName {
#####################################################################
# This method returns the name of the cdtFile

    return $_[0]->{$kCdtFileName};
}


#####################################################################
sub _cdtBase {
#####################################################################
# This method returns the base name string of the files comprising of
# the dataset, sans suffices

    return $_[0]->{$kCdtBase};
}


#####################################################################
sub _cdtPath {
#####################################################################
# This method returns the path to the cdt file of thebeing converted
# into a dataset

    return $_[0]->{$kCdtPath};
}


######################################################################
sub __ensureDirectoriesExist {
######################################################################
# This subroutine checks to see that the full outpath is created if
# necessary, by extended a previouslt validated filepath.  It is
# tended for use only when initializating a dataset, where the dataset
# directories might need to be created and appended to the data and
# image out paths

    my ($self, $path, $possibleExtension) = @_;

    my @dirnames = split(/\//, $possibleExtension);

    $dbg && print "Ensuring that all directories exist for the dataset initialization\n";
    $dbg && print "\t$path + @dirnames\n";


    $path = &EnsureTrailingSlash($path);

    while (my $dir = shift(@dirnames)) {

	# extend the tree if requested
	$path .= "$dir/";

	# does it exist, or should we make it (new directory)?
	unless (&DirectoryIsValid($path)) {

	    $dbg && print "\tcreating $path directory\n";

	    # if not, create it first...
	    mkdir($path, 0775) || die "Couldn't create directory: $path";

	}
	$path = &EnsureTrailingSlash($path);
    }

    return $path; # this should be the validated, extended path

}


#####################################################################
sub datapath {
#####################################################################
# This method returns the path to which data files either written
# or read from

    return $_[0]->{$kDataPath};
}


#####################################################################
sub imagepath {
#####################################################################
# This method returns the path to which image files are either written
# or read from

    return $_[0]->{$kImagePath};
}


#####################################################################
sub contrast {
#####################################################################
# This method returns the contrast

    return $_[0]->{$kContrast};
}


#####################################################################
sub colorScheme {
#####################################################################
# This method returns the colorScheme

    return $_[0]->{$kColorScheme};
}

#####################################################################
sub corrCutoff {
#####################################################################
# This method returns the correlation cutoff

    return $_[0]->{$kCorrCutoff};
}


#####################################################################
sub fileBaseName {
#####################################################################
# This method returns the base name string of the files comprising of
# the dataset, sans suffices

    return $_[0]->{$kFileBaseName};
}


#####################################################################
sub height {
#####################################################################
# This method returns the number of data rows in the cdtFile

    return $_[0]->{$kHeight};
}


#####################################################################
sub width {
#####################################################################
# This method returns the number of data columns in the cdtFile

    return $_[0]->{$kWidth};
}

#####################################################################
sub __config{
#####################################################################
# This private method returns the config object that was used during
# construction

    return $_[0]->{$kConfig};

}

#####################################################################
sub __cdtFileObject {
#####################################################################
# This private method returns a cdtFile Object.  If one does not exist
# within the object, one will be created.  If one does exist, that
# will simply be returned.  This will likely fail for sets that are
# already converted, because the .cdt file is not copied into the
# dataset location.  This is a design issue that needs to be
# discussed, in addition to the fact that it is private method, when
# it seems like other software might actually *want* to retrieve the
# Datamatix object

    my $self = shift;

    if (!exists($self->{$kCdtFileObject})){ # we need to create one

	$self->{$kCdtFileObject} = Microarray::DataMatrix::CdtFile->new(file   => $self->_cdtFileName,
									tmpDir => $self->__config->tmpPath);
    }

    return $self->{$kCdtFileObject};
}


#####################################################################
sub __shouldInitialize {
#####################################################################
# This private method returns whether the object needs initialization

    return $_[0]->{$kShouldInitialize};
}


#####################################################################
sub __initializeDataset { 
#####################################################################
# This method creates a new dataset from a CDT (clustered data) file.
# The CDT file format was defined by Michael Eisen for his Windows
# applications TreeView and Cluster. It has certain drawbacks, for
# example not more then two columns per gene can be used to store
# additional information.  This can be partly resolved by putting more
# data into one record field.  A kludgy fix.

    my $self = shift;

    $self->__lock;   # lock dataset

    # first extract salient info from cdtfile, and 
    # create the correlations files

    $self->__dissectCDT;
    $self->__prepareCorrelations;    
    $self->__compressCorrelations;


    # should have enough data dissected so far to load the experiment
    # info, and we'll need these for the image header, so load them

    $self->__loadExptInfo;

    # now create the required images
    my $imageMaker = Microarray::DatasetImageMaker->new();
    $imageMaker->makeImage('dataset' => $self,
			   'type'    => 'matrix');
    $imageMaker->makeImage('dataset' => $self,
			   'type'    => 'header');    
    
    # now write out our 'meta' information,
    # for quick access later on

    $self->__prepareMetaFile;

    $self->__unlock; # unlock dataset
    
}


#####################################################################
sub __lock {
#####################################################################
# This method locks the dataset

    my $self = shift; 
    my $lockFile = $self->datapath.$self->fileBaseName.$kLockSuffix;
    open (OUT, ">".$lockFile) || die "Cannot lock dataset using lockfile $lockFile : $!";
    close (OUT);

}


#####################################################################
sub __unlock {
#####################################################################
# This method unlocks the dataset

    my $self = shift; 
    my $lockFile = $self->datapath.$self->fileBaseName.$kLockSuffix;
    unlink ($lockFile);
}


#####################################################################
sub __dissectCDT {
#####################################################################
# This method determines the contents of the cdtfile, and stores some
# of the cdtMeta data for quick retrieval.  Note that the previous
# version did its own parsing of the cdtFile.  This is now delegated
# to the cdtFile object.

    my $self = shift;

    my $cdtFileObject = $self->__cdtFileObject;

    $self->__setWidth($cdtFileObject->numColumns);
    $self->__setHeight($cdtFileObject->numRows);

    $self->__saveCdtExptNames($cdtFileObject->columnNamesArrayRef);
    
    $cdtFileObject->createIndexFile($self->datapath.$self->fileBaseName.$kFeatureSuffix);
    $cdtFileObject->createRawMatrixFile($self->datapath.$self->fileBaseName.$kMatrixSuffix);

}


######################################################################
sub __saveCdtExptNames {
######################################################################
# This method (we may eliminate it later) save the names of the data
# columns from the cdtFile (these are usually the experiment names) to
# a file.  This is later used by GeneXplorer, but also provides a
# quick way of looking up the data, without having to read the cdtFile
# in.

    my ($self, $exptNamesARef) = @_;

    my $file = $self->datapath.$self->fileBaseName.$kExptInfoSuffix;

    # write index number and name to file

    open (OUT, ">".$file) || die "Cannot write out experiment info to $file : $!";

    print OUT "ID\tNAME\n";

    for (my $i=0; $i < @{$exptNamesARef}; $i++){
	
	print OUT $i, "\t", $exptNamesARef->[$i], "\n";	
	
    }
    
    close (OUT);    

}


#####################################################################
sub __prepareCorrelations {
#####################################################################
# This method prepares a correlations file 

    my $self = shift;

    # first we have to create a pcl file, with an index in the first
    # column

    my $pclFileName = $self->datapath.$self->fileBaseName.$kPclSuffix;

    print "pcl name:  $pclFileName\n";

    print "tmp path: ".$self->__config->tmpPath."\n";

    $self->__createIndexedPclFile($pclFileName);

    my $pcl = Microarray::DataMatrix::PclFile->new(tmpDir => $self->__config->tmpPath,
						   file   => $pclFileName);

    # then use the pcl file to create correlations

    $pcl->createCorrelationsFile(cutoff=>$self->corrCutoff);

    # Now we can get rid of the pcl file
    unlink $pclFileName || warn "Couldn't unlink $pclFileName : $!";
    
}


#####################################################################
sub __createIndexedPclFile{
#####################################################################
# This method creates a pcl file from the cdt file that was used to
# instantiate the object.  This is coded here, rather than using the
# cdtFile method to convert to a pcl, because the pcl file must have 
# an index for it's names, rather than the names themselves.

    my ($self, $pclFile) = @_;

    open (IN, $self->_cdtFileName) || die "Cannot open cdt file ".$self->_cdtFileName." : $!";

    print "trying to create $pclFile \n\n";

    open (OUT, ">".$pclFile) || die "Cannot create $pclFile : $!";

    my $count = 1;
    my $index = 0;
    my $hasGtr = 0;
    my @line;
    my $numColumns;

    while (<IN>){

	chomp;

	@line = split("\t", $_, -1);

	if ($count == 1){

	    if ($line[0] eq "GID"){

		shift (@line);
		$hasGtr = 1;

	    }

	    $numColumns = scalar(@line);

	    print OUT join("\t", @line), "\n";
	    print OUT "EWEIGHT\t\t";

	    print OUT "\t1" x (scalar(@line)-3), "\n";	    

	    $count++;

	    next;

	}elsif ($count == 2){

	    $count++;

	    next if ($line[0] eq "AID");

	}

	# if we get here, it's a data line

	shift (@line) if $hasGtr;

	next if !@line;

	$line[0] = $index;

	if (scalar(@line) != $numColumns){

	    die "In your cdtFile, data line $index has ".scalar(@line)." columns, instead of $numColumns.\n";

	}

	print OUT join("\t", @line), "\n";

	$index++;

    }

    close OUT;
}


#####################################################################
sub __compressCorrelations {
#####################################################################
# This method takes a correlations file as output by Gavin Sherlocks
# correlations program.  These represent the correlation values of a
# certain gene (array element) intensity vector vs. all other vectors
# in a data matrix.
# The output generated is a binary representation of the list of
# correlation values for each row in the data matrix (= expression
# vectors).
# 
# The file is built like this:
# ############################
# name        content           bytes
# ################################################
# header
# ################################################
# index_size  length of index   2
# index       offset for rows   index_size * 2
# ################################################
# body
# ################################################
# data 1..n   correlation data  4 * look up in index
# -> index    correlated vector 2 \
# -> corr     correlation       2 / 2 words (16 int)

# The correlation data is stored in lists of pairs of the most
# correlated vectors index number (row in the table) and the
# correlation value. The correlation value has been multiplied by
# (2^16)-1 (65535) to make it an integer. To retrieve the original
# value, divide the integer by (2^16)-1.  No negative correlation
# values are allowed.

    my $self = shift; 

    my $corrFile = $self->datapath.$self->fileBaseName.$kStdCorrSuffix;

    my $header     = "";
    my $numVecs    = 0;
    my $body       = "";
    
    open(IN, $corrFile) || die "cannot open correlations file $corrFile: $!\n";

    while (<IN>){

	chomp;

	my @values         = split(/\t/, $_);   # split each row, containing the index/correlation pairs
	my $index          = shift @values;     # first value in row is the index of the vector we correlate to
	my $numCorrVectors = scalar(@values)/2; # determine how many correlated vectors exist for this one (pairs/2)
	
	for (my $j=1; $j < @values; $j += 2) { # look at the correlations

	    # multiply correlation values and make them into an int
	    # between 0 and 65535

	    $values[$j] = int($values[$j] * 65535);

	}
	
	# add the number of pairs to the file header
	$header .= pack("n", $numCorrVectors);
	
	# pack values into string of unsigned ints
	# and add the packed row to the file body

	$body .= pack("n*", @values);

	$numVecs++;
	
    }
    
    close IN;

    # store the number of vectors as first word of header

    $header = pack("n", $numVecs).$header;
    
    my $binFile = $self->datapath.$self->fileBaseName.$kBinCorrSuffix;
    
    open (OUT, ">$binFile") || die "cannot open binary correlations $binFile: $!\n";

    print OUT $header, $body;

    close (OUT);
    
    # now get rid of the stdCor file, as we don;t need it now

    unlink $corrFile || warn "Can't remove $corrFile : $!\n";

}


#############################################################################
sub __prepareMetaFile {
#############################################################################
# This method writes out a file of meta information that pertain to
# the dataset, in the form of name=value pair.

    my $self = shift;

    my $file = $self->datapath.$self->fileBaseName.$kMetaSuffix;

    open(OUT, ">".$file) || die "Cannot create meta file, $file : $!";

    foreach my $key (@metaColumns) {

	print OUT $key, "=", $self->{$key}, "\n";

    }

    close(OUT);
    
}


#####################################################################
sub _load_meta {
#####################################################################
# This method loads in previously cached meta data

    my $self = shift;

    my $filename = $self->datapath.$self->fileBaseName.$kMetaSuffix;
 
    open(IN, $filename) || die "cannot open _meta_ $filename $!";

    while (<IN>){

	chomp;
	
	my ($key, $value) = split("=",$_);

	$self->{$key} = $value;

    }

    close IN;

}

###
#
#
# STUFF FROM HERE ON DOWN IS CRAP.... so says Gavin?
#
###

# JCM note: Tried removing it, but many of these subroutines are still
# used by both this class and Explorer.  My guess is that the rest are
# likely used by other clients that Christian wrote

######################################################################
sub __loadExptInfo {
######################################################################
## This method loads the expt_info data

    my $self = shift;
    $self->{EXPT_INFO} = $self->__load_table("expt_info");
}


######################################################################
sub __loadFeatureInfo {
######################################################################

    my $self = shift;
    $self->{FEATURE_INFO} = $self->__load_table("feature_info");
}


######################################################################
sub __load_table {
######################################################################
# loads an ASCII table. It is expected that the first row contains the
# column headers It is also expected that the first column contains
# numeric id's starting at '0'.  returns a reference to the table
# structure

    my ($self, $tableName) = @_;

    my $file = $self->datapath.$self->fileBaseName.".".$tableName;

    my ($table, $index, $i, @record);

    open(IN, $file) || die "cannot open _table $file $!\n";
    
    my $firstrow  = (<IN>);
    chomp($firstrow);

    my @head = split("\t", $firstrow, -1);

    # since the first columns header is always 'ID' we discard it
    shift @head;

    while (<IN>) {

	 chomp;
	 @record     = split("\t", $_, -1);
	 $index   = shift @record;

	 $i = 0;
	 my %record = map { $head[$i++] => $_ } @record;
	 $$table[$index] = \%record;
    
    }

    return $table;

}


######################################################################
sub image {
######################################################################
# Returns the data matrix as a GD::Image, drawn with 1x1 pixel per
# value at the contrast last used/initialized with $ds->new()
#
# Usage: $ds->image();

    my $self = shift;

    my $type = shift;

    my $image;

    if ($type eq "matrix") {
	 $image = &_load_image($self->imagepath.$self->fileBaseName.".data_matrix.$kImgType");
	 return $image;
    }

    if ($type eq "expt_info") {
	 $image = &_load_image($self->imagepath.$self->fileBaseName.$kInfoGifSuffix);
	 return $image;
    }

    die "This type of image is not known\n";

}


######################################################################
sub _load_image {
######################################################################
# this protected method just opens up the previously stored matrix
# image (from dataset initialization) , created a GD::Image object
# with it, and returns it.  Possible bug: it relies on GD::Image
# version (>1.19) to pick $kImgType, when perhaps it should rely on
# the filename suffix (.gif, .png) instead.  This may prevent the
# portability of intact datasets from one filesystem to another, but
# in the end, you're always going to be limited by the version of GD...

    my $filename = shift;

    open(IN, $filename) || die "cannot open _image $filename! $!\n";

    my $funcname = "newFrom".ucfirst($kImgType);
    my $image = GD::Image->$funcname(*IN);
    return $image;

}


######################################################################
#sub vector {
######################################################################
#
#    my $self  = shift;
#    my $index = @_;
#    
#    # load the data matrix only on demand
#    if ( !defined( $self->{MATRIX} ) ) {
#
#	 $self->_load_matrix();
#
#    }
#    
#    return wantarray ? @{$self->{MATRIX}[$index]} : $self->{MATRIX}[$index];
#
#}
#
#
######################################################################
#sub _load_matrix {
######################################################################
#
#    my $self = shift;
#
#    my ($matrix, $index);
#
#    my $filename = $self->datapath.$self->fileBaseName.".data_matrix";
#
#    $dbg && print "\tload matrix filename: $filename\n";
#
#    $matrix = [ ];
#
#    open(IN, $filename) || die "cannot open _matrix_ $filename $!\n";
#
#    while (<IN>) {
#
#	 chomp;
#	 my @row   = split("\t", $_, -1);
#	 $index = shift @row;
#
#	 $$matrix[$index] = \@row;	
#	 
#    }
#
#    $self->{MATRIX} = $matrix;
#
#}
#
######################################################################
#sub getMatrixValue {
######################################################################
#
#    my $self = shift;
#
#    my $x = shift;
#    my $y = shift;
#
#    if ($x > $self->width || $y > $self->height || $x < 0 || $y < 0) {
#	 die  "index values (x = $x, y = $y) exceed range in getMatrixValue!\n";
#    }
#
#    return $self->{MATRIX}[$y][$x];
#    
#}
#
#
######################################################################
#sub _save_table {
######################################################################
#
#    ### just started, has to be filled in 2000-10-
#
#    # saves an ASCII table. It is expected that the first row contains the column headers
#    # It is also expected that the first column contains numeric id's starting at '0'.
#    # returns a reference to the table structure
#    my $self = shift;
#    my $suffix = shift;
#
#    my $file = $self->datapath;
#    $file .= $self->fileBaseName;
#    
#    # save the feature table
#    if ($suffix =~ /feature/i) {
#
#	 $file .= ".feature_info";
#
#	 my @keys = $self->getFeatureKeys();
#
#	 open( OUT, ">$file" ) || die "cannot open $file in _save_table: $!\n";
#
#	 my $header = "ID\t".join("\t",@keys);
#
#	 $header .= "\n";
#
#	 print OUT $header;
#
#	 for(my $i=0;$i<$self->height;$i++) {
#	     
#	     print OUT $i;
#	     foreach (@keys) {
#		 print OUT "\t".$self->getFeature($i,$_);
#	     }
#	     print OUT "\n";
#
#	 }
#
#	 close(OUT);
#
#    }
#
#    # save experiment table
#    if ($suffix =~ /expt/) {
#
#	 my @keys = $self->getExperimentKeys();
#
#	 $file .= ".expt_info";
#
#	 open(OUT, ">$file") || die "cannot open $file in _save_table: $!\n";
#
#	 for(my $i=0;$i<$self->width;$i++) {
#	     
#	     print OUT $i;
#	     foreach (@keys) {
#		 print OUT "\t".$self->getFeature($i,$_);
#	     }
#	     print OUT "\n";
#
#	 }
#
#	 close(OUT);
#
#    }
#
#    
#    
#}
#
######################################################################
#sub serialize {
######################################################################
# writes the dataset annotation to the repository, used in conjunction
# with setFeature()
#
#    my $self = shift;
#
#    $self->_save_table('feature');
#    
#}
#
######################################################################
#sub getExperimentKeys {   # wrapper to keep interface intact
######################################################################
#    my $self = shift;
#
#    my @keys = ( keys %{$self->{EXPT_INFO}[0]} );
#
#    return wantarray ? (@keys) : \@keys;
#
#}
#
#######################################################################
#sub experiment_keys {
#######################################################################
#
#    my $self = shift;
#    my @keys = ( keys %{$self->{EXPT_INFO}[0]} );
#
#    return wantarray ? (@keys) : \@keys;
#
#}
#
######################################################################
sub experiment {
######################################################################

    my $self = shift;
    my( $index, $field ) = @_;

    if ( $index > $self->width() ) {
	 die "error: index larger then data\n";
    }
    
    if ( exists( $self->{EXPT_INFO}[$index]{$field} ) ) {
	 return $self->{EXPT_INFO}[$index]{$field};
    } else {
	 return "$index $field";
    }  

}

######################################################################
#sub featureAttributeExists {
######################################################################
# Returns true if the attribute passed as an argument
# (e.g. 'CHROMOSOME') exists
#
# Usage: $ds->featureAttributeExists(<column_name>)
#
#
#    my $self = shift;
#    my $attr = shift;
#
#    return (exists($self->{FEATURE_INFO}->[0]->{$attr}));
#
#}

#####################################################################
sub getFeatureKeys {
#####################################################################
# returns the keys (attributes) for the features (gene expression row
# vectors)
#
#Usage: $ds->getFeatureKeys()

    my $self = shift;
    
    my @keys = ( keys %{$self->{FEATURE_INFO}[0]} );

    return wantarray ? (@keys) : \@keys;

}


#####################################################################
sub feature {
######################################################################
# required by the search function of Explorer

    my $self = shift;
    my( $index, $field ) = @_;

    if ( $index > $self->height ) {
	 return "error: index larger then data\n";
    }
    
    if ( exists( $self->{FEATURE_INFO}->[$index]->{$field} ) ) {
	 return $self->{FEATURE_INFO}->[$index]->{$field}
    } else {
	 return "no field by this name: $field.";
    }  
}


#####################################################################
sub getFeature {
#####################################################################

    my $self = shift;
    my( $index, $field ) = @_;

    if ( $index > $self->height ) {
	 return "error: index larger then data\n";
    }
    
    if ( exists( $self->{FEATURE_INFO}->[$index]->{$field} ) ) {
	 return $self->{FEATURE_INFO}->[$index]->{$field}
    } else {
	 return "no field by this name: $field.";
    }  
}


######################################################################
#sub setFeature {
######################################################################
# Sets the column <columns_name> in row <index> to <value> [also see
# serialize() ] JCM: This is probably for updating the dataset
#
#
#    my $self = shift;
#    my( $index, $field, $newval ) = @_;
#
#    if ( $index > $self->height ) {
#
#	 return "error: index larger then data\n";
#
#    }
#    
#    if ( exists( $self->{FEATURE_INFO}->[$index]->{$field} ) ) {
#	 
#	 $self->{FEATURE_INFO}->[$index]->{$field} = $newval;
#	 
#    } else {
#	 
#	 # this adds a column to the table. We iterate over all
#	 # rows and add the new row/record field
#	 for (my $i=0;$i<$self->height;$i++) {
#	     $self->{FEATURE_INFO}->[$i]->{$field} = '';
#	 }
#	 
#	 # after we added the column, we assign the passed value
#	 $self->{FEATURE_INFO}->[$index]->{$field} = $newval;
#	 
#    }  
#    
#}
#


#####################################################################
sub search {
#####################################################################
# Returns an array of data matrix row numbers where <query> matched in
# column <column_name>.  When using 'ALL' as <column_name>, all
# columns will be searched

    my $self = shift;

    my $query = shift;
    my $field = shift;

    my( @keys, @hits );

    if ($dbg) { print "Now searching $query in $field...\n", "<br>" };

    # search a specific field...
    if ( $field eq "ALL" ) {
	 @keys = $self->getFeatureKeys();
    # ... or all fields
    } else {
	 push @keys, $field;
    }
	 
    for(my $i=0;$i<$self->height;$i++) {

	 if ( $self->_search_feature( $i, $query, \@keys ) ) {
	     push @hits, $i;
	 } 

    }

    return (@hits);

}


#####################################################################
sub _search_feature {
#####################################################################
# usage: $hit = $self->_search_feature( 100, "kinase", ['ACC','NAME','SYMBOL'])
############################################################################-
# this function returns true, if the feature queried contains the passed
# string values(s). The parameters to this function are:
# - required: the index number of the feature
# - required: a search term
# - optional: an array reference, containing the names of fields to search,
#   if not passed, all fields will be searched.

    my $self = shift;

    my $index = shift;
    my $query = shift;

    my $field_aref = shift;

    my $field;

    # search field(s) for the query
    foreach $field ( @{$field_aref} ) {

	 if ( $self->feature( $index, $field ) =~ /$query/i ) {

	     if ($dbg) { print "found $query in field $field in feature $index", "<br>" }
	 
	     return 1;
	 }
    }
    
    # if we got here, nothing was found, return 'FALSE'
    return 0;

}


#####################################################################
sub correlations {
#####################################################################
# Returns the precalculated correlation values for row <index>.  Up to
# 50 correlations values > 0.5 are stored.  As an example client
# usage, see Explorer's/gx retrieval of those profiles correlated to
# the query (user-clicked profile within zoom view).




    my $self = shift;

    my( $seed, $neighbours, $corrs ) = @_;

    my $corr_file = $self->datapath.$self->fileBaseName.$kBinCorrSuffix;

    &_get_correlations(
			$corr_file, 
			$seed, 
			$neighbours,
			$corrs
			);
    
    
}


#####################################################################
sub _get_correlations {
#####################################################################
# required for Explorer to retrieve those profiles highly correlated
# to the query (user-clicked profile within zoom view)


    my (
	 $file, 
	 $startVector,
	 $cVec_aref,
	 $cCor_aref
	 ) = @_;

    my ($tmp, $numRows, $indexSize, $index, $vecOffset, $vector);
    my (@indices, @vecOffsets, @vecSizes);

    open (IN, $file) || die "cannot open _correlations_ $file: $!\n";

    # read the first word, indicating the number of rows 
    # contained in the body 
    read(IN, $tmp, 2); 

    $numRows = unpack("n", $tmp); 

    # if the function is only being called with the filename, return the number of correlations
    if ($startVector eq "") {
	 return $numRows;
    }

    if ( ($startVector < 0) || ($startVector > $numRows-1) ) {
	 die "Error: loadCompressedCorrelations: start vector ($startVector) wrong size\n";
    }

    $indexSize = $numRows * 2;  # the index that follows in the head is numRows words (= 2 bytes)

    # after this value, an index containing the same number of words, 
    # each indicating the number of correlation values stored per row, follows
    # reading from the current filepointer is equivalent to setting it with seek(IN, 2, 0);
    read(IN, $index, $indexSize );

    @indices = unpack("n*", $index);

    # initialize the first offset outside loop
    $vecOffsets[0] = 0;
    $vecSizes[0] = $indices[0] * 4;
    $vecOffset = $vecSizes[0];

    # build the offset size for all entries in body, since the index only contains the number
    # of correlations for the individual gene. We need cumulative offset values
    for (my $j=1;$j<=$#indices;$j++) {

	 my $vecSize       = $indices[$j] * 4;
	 $vecSizes[$j]     = $vecSize;
	 $vecOffset       += $vecSize;    # number of reference/correlation pairs, each pair is two words ( = 4 bytes total)  
	 $vecOffsets[$j+1] = $vecOffset;

    }

    seek(IN, $vecOffsets[$startVector], 1);  # go to position for this vectors correlation data in file
    read(IN, $vector, $vecSizes[$startVector]);

    my @values = unpack("n*", $vector);

    my $iter = 0;
    for (my $k=0; $k<=$#values; $k++) {
	 if (!($k % 2)) {
	     $cVec_aref->[$iter] = $values[$k];
	 } else {
	     $cCor_aref->[$iter] = sprintf("%.4f", $values[$k] / 65535);
	     $iter++;
	 }
    }

    close(IN);

}


######################################################################
#sub size {
######################################################################
## This method returns the size of the dataset.  It is based on the
## assumption (which is currently wrong) that all file in the dataset
## start with the dataset name.
#
#    my $self = shift;
#
#    if ( exists($self->{'SIZE'}) ) {
#
#	 return $self->{'SIZE'};
#
#    } else {
#
#	 my $stem = $self->datapath().$self->fileBaseName.".*";
#	 
#	 my @files = glob($stem);
#	 
#	 my $size;
#	 
#	 for (@files) {
#	     $size += (-s $_);
#	 }
#
#	 $self->{'SIZE'} = $size;
#	 
#	 return $self->{'SIZE'};
#
#    }
#
#}

1; # to make perl happy


__END__

#####################################################################
#
#  POD Documentation from here on down
#
#####################################################################

=pod

=head1 NAME

Microarray::CdtDataset - an abstraction to the files produced from clustering

=head1 Abstract

 This package implements an object that serves as an abstraction to a
 cdtDataset.  It is different than the Microarray::DataMatrix::CdtFile
 abstraction, because it deals with the cdtFile in the context of gtr
 and/or atr files.  It also provides methods by which the geneXplorer
 program can interact with a cdtDataset.
    The essential purpose of CdtDataset's initialization functions is to
 de-construct the .cdt file into its constituent data parts of the
 dataset:
    1) the data matrix (.data_matrix)
    2) the bioassay names or slidenames (.expt_info)
    3) the annotations of the spotted features/reporters/sequences
       (.feature_info)
    4) any additional meta information about the set (.meta)
    5) additionally, it computes or creates the following:
        a) a binary file containing a list of feature-feature
           correlations (.binCor) 
        b) a 2-color image representation of the data matrix
           (.data_matrix.png)
        c) a image representation of the expt_info file
           (.expt_info.png)

=head1 Known Issues

 There are good reasons to add additional meta data to a dataset,
 including possibly the organism of the set or the location of the
 default display configuration file to display the .feature_info.
 These would probably have to be called in the constructor.

=head1 Future Plans

 Currently, only the .cdt file of a clustered dataset
 is utilized.  In the future, the other data files detailing the
 clustering [gene tree(.gtr) and array tree(.atr)] should be
 utilized, and DatasetImageMaker should export suitable image
 representations for these files.  Furthermore, It would be great to
 pull general dataset methods from this class into a future class,
 Microarray::Dataset.  That way, you could make a MageMLDataset class
 as well, and still keep many of the general class attributes/methods
 in the same locations.  Microarray:Dataset would inherit constructor
 methods (i.e. knowledge of the file structure) from either
 CdtDataset orMageMLDataset at initialization (perhaps a run-time ISA
 declaration within the constructor).  Otherwise, I don't see a huge
 advantage to having these specialized (and somewhat misnamed)
 classes, in the sense that Dataset only need to know how to parse
 the initialization file while converting a new dataset


=head1 Instance Constructor

=head2 new

 This is the constructor.  There are two modes in which the
 constructor can be used.  In one mode, it will create various files
 which support the dataset, using the cdt, (and hopefully in the
 future, gtr and atr files).  In the second mode, it will assume that
 these files already exist and just return the constructed objevt.
 Thus when a dataset is first created, there will be the overhead of
 creating the additional files, but subsequent creation of a
 cdtDataset object will not have that overhead.  The constructor
 takes the following arguments:
 name         :  The fully qualified name of the dataset (slash/delimited),
                 which encodes the location and stem of the files,
                 without any extensions, and with no path
                 information. If the 'initialize' argument is set
                 (see below), a directory tructure of the same name
                 will also be created to contain the exported data
                 files.
 datapath     :  This required path prefix is where any newly created data
                 files should be placed (or read from).
 imagepath    :  An optional path prefix where any newly created image files
                 should be placed (or read from). Will default to
                 datapath if none is specified.
 contrast     :  If a dataset is being instantiated for the first
                 time, then a contrast is needed for image
                 generation.  If no contrast is provided, then a
		  default value of 4 will be used.  As the data are
		  expected to be in log base 2, this corresponds to a
		  16-fold change as the maximum color in any image.
 colorscheme  :  Can either be 'red/green' (the default if none is
                 specified) or 'yellow/blue'
 initialize   :  A filepath of the originating .cdt file indicate
                 whether to initialize all the required supporting
                 files that a cdtDataset needs.  This defaults to 0
                 (assumes that the necessary supporting files already
                 exist.  If it is a filepath, then the dataset is
                 initialized using it
 Note that if you supply a contrast, you must set initialize to 1, as
 a contrast is useless in the absence of initialization.  Both the
 'dataset' and 'path' arguments are absolutely required.
 Usage, eg if you have a file:
    my $ds = Microarray::CdtDataset->new(name=>dataset/name, # name of the dataset
		  			       datapath=>$dir,     # prefix path where dataset files will be written
					       contrast=>2,        # image contrast
					       initialize=>/path/to/file.cdt);

=head1 Instance Methods

=head2 name

 This method returns the fully qualified name of the dataset

=head2 contrast

 This method returns the contrast

=head2 colorScheme

 This method returns the colorScheme

=head2 fileBaseName

 This method returns the base name string of the files comprising of
 the dataset, sans suffices

=head2 height

 This method returns the number of data rows in the cdtFile

=head2 width

 This method returns the number of data columns in the cdtFile

=head2 image

 Returns the data matrix as a GD::Image, drawn with 1x1 pixel per
 value at the contrast last used/initialized with $ds->new()
 Usage: $ds->image();

=head2 experiment


=head2 getFeatureKeys

 returns the keys (attributes) for the features (gene expression row
 vectors)
Usage: $ds->getFeatureKeys()

=head2 feature

 required by the search function of Explorer

=head2 getFeature


=head2 search

 Returns an array of data matrix row numbers where <query> matched in
 column <column_name>.  When using 'ALL' as <column_name>, all
 columns will be searched

=head2 correlations

 Returns the precalculated correlation values for row <index>.  Up to
 50 correlations values > 0.5 are stored.  As an example client
 usage, see Explorer's/gx retrieval of those profiles correlated to
 the query (user-clicked profile within zoom view).

=head1 Protected Methods

=head2 _cdtFileName

 This method returns the name of the cdtFile

=head2 _cdtBase

 This method returns the base name string of the files comprising of
 the dataset, sans suffices

=head2 _cdtPath

 This method returns the path to the cdt file of thebeing converted
 into a dataset

=head2 datapath

 This method returns the path to which data files either written
 or read from

=head2 imagepath

 This method returns the path to which image files are either written
 or read from

=head2 _load_meta

 This method loads in previously cached meta data

=head2 _load_image

 this protected method just opens up the previously stored matrix
 image (from dataset initialization) , created a GD::Image object
 with it, and returns it.  Possible bug: it relies on GD::Image
 version (>1.19) to pick $kImgType, when perhaps it should rely on
 the filename suffix (.gif, .png) instead.  This may prevent the
 portability of intact datasets from one filesystem to another, but
 in the end, you're always going to be limited by the version of GD...

=head2 _search_feature

 usage: $hit = $self->_search_feature( 100, "kinase", ['ACC','NAME','SYMBOL'])
 this function returns true, if the feature queried contains the passed
 string values(s). The parameters to this function are:
 - required: the index number of the feature
 - required: a search term
 - optional: an array reference, containing the names of fields to search,
   if not passed, all fields will be searched.

=head2 _get_correlations

 required for Explorer to retrieve those profiles highly correlated
 to the query (user-clicked profile within zoom view)

=head1 Private Methods

=head2 __init

 This method takes care of all of the initialization of the
 attributes of the cdtDataset

=head2 __checkAndSetConstructorArguments

 This private method checks that the constructor arguments pass all
 sanity checks, and that files that should exist do exist.

=head2 __checkAndSetInitializationState

 This method checks and sets whether the object needs full
 initialization.  There are meant to be 2 initilization requests.
 The first (initialization=><path>) would request that the dataset be
 created de novo from an initial file, and the second
 (initialization=>1) would just remake the images with a different
 constrast and different colors.  The second initialization has not
 been adequately tested.

=head2 __checkAndSetDataPath

 This private method checks that an Path is supplied, that
 corresponds to an existent directory, then stores it in the object.

=head2 __checkAndSetImagePath

 This private method checks that an Path is supplied, that
 corresponds to an existent directory, then stores it in the object.

=head2 __checkAndSetDatasetName

 This method checks that a dataset was given to the constructor.  In
 addition because CdtDataset creates and stores all its images and data
 in a directory hierarchy, the initially specified data and image
 paths are augmented with the dataset name directories (which are
 created upon initialization)


=head2 __checkAndSetContrast

 This method determines if the contrast is valid, and then stores the
 value in the object

=head2 __checkAndSetColorScheme

 This method determines if the colorscheme is valid, and then stores
 the value in the object

=head2 __checkRequiredFilesExist

 This method checks that all the required files for the dataset exist
 If they do not, it will cause a fatal error

=head2 __setCdtInfo

 this subroutine takes the initalize arguement and store the path and
 the stem of the .cdt filename

=head2 __setFileBaseName

 This method allows the filename stem (no suffix) of the datafiles
 use to initialize the dataset to be set

=head2 __setDataPath

 This method allows the path to where the data files for the dataset
 exist to be set

=head2 __setImagePath

 This method allows the path to where the image files for the dataset
 exist to be set

=head2 __setDatasetName

 This method allows the name of the dataset to be set.

=head2 __setCdtFileName

 This method sets the name of the cdtFile

=head2 __setContrast

 This method allows the contrast to be set.

=head2 __setColorScheme

 This method allows the colorscheme to be set.

=head2 __setShouldInitialize

 This method allows a flag to be set as to whether full
 initialization need to take place

=head2 __setHeight

 This private method allows the 'height' of the dataset to be set.
 This in fact corresponds to the number of rows in the cdt file.

=head2 __setWidth

 This private method allows the 'height' of the dataset to be set.
 This in fact corresponds to the number of rows in the cdt file.

=head2 __ensureDirectoriesExist

 This subroutine checks to see that the full outpath is created if
 necessary, by extended a previouslt validated filepath.  It is
 tended for use only when initializating a dataset, where the dataset
 directories might need to be created and appended to the data and
 image out paths

=head2 __cdtFileObject

 This private method returns a cdtFile Object.  If one does not exist
 within the object, one will be created.  If one does exist, that
 will simply be returned.  This will likely fail for sets that are
 already converted, because the .cdt file is not copied into the
 dataset location.  This is a design issue that needs to be
 discussed, in addition to the fact that it is private method, when
 it seems like other software might actually *want* to retrieve the
 Datamatix object

=head2 __shouldInitialize

 This private method returns whether the object needs initialization

=head2 __initializeDataset

 This method creates a new dataset from a CDT (clustered data) file.
 The CDT file format was defined by Michael Eisen for his Windows
 applications TreeView and Cluster. It has certain drawbacks, for
 example not more then two columns per gene can be used to store
 additional information.  This can be partly resolved by putting more
 data into one record field.  A kludgy fix.

=head2 __lock

 This method locks the dataset

=head2 __unlock

 This method unlocks the dataset

=head2 __dissectCDT

 This method determines the contents of the cdtfile, and stores some
 of the cdtMeta data for quick retrieval.  Note that the previous
 version did its own parsing of the cdtFile.  This is now delegated
 to the cdtFile object.

=head2 __saveCdtExptNames

 This method (we may eliminate it later) save the names of the data
 columns from the cdtFile (these are usually the experiment names) to
 a file.  This is later used by GeneXplorer, but also provides a
 quick way of looking up the data, without having to read the cdtFile
 in.

=head2 __prepareCorrelations

 This method prepares a correlations file 

=head2 __createIndexedPclFile

 This method creates a pcl file from the cdt file that was used to
 instantiate the object.  This is coded here, rather than using the
 cdtFile method to convert to a pcl, because the pcl file must have 
 an index for it's names, rather than the names themselves.

=head2 __compressCorrelations

 This method takes a correlations file as output by Gavin Sherlocks
 correlations program.  These represent the correlation values of a
 certain gene (array element) intensity vector vs. all other vectors
 in a data matrix.
 The output generated is a binary representation of the list of
 correlation values for each row in the data matrix (= expression
 vectors).
 The file is built like this:
 name        content           bytes
 header
 index_size  length of index   2
 index       offset for rows   index_size * 2
 body
 data 1..n   correlation data  4 * look up in index
 -> index    correlated vector 2 \
 -> corr     correlation       2 / 2 words (16 int)

=head2 __prepareMetaFile

 This method writes out a file of meta information that pertain to
 the dataset, in the form of name=value pair.

=head2 __loadExptInfo

# This method loads the expt_info data

=head2 __load_table

 loads an ASCII table. It is expected that the first row contains the
 column headers It is also expected that the first column contains
 numeric id's starting at '0'.  returns a reference to the table
 structure

=head1 Authors

John C. Matese
jcmatese@genome.stanford.edu

=cut
