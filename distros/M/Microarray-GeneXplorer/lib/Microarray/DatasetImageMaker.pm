package Microarray::DatasetImageMaker;

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


# Class: Microarray::DatasetImageMaker
#
# Microarray::DatasetImageMaker is a class that accepts a
# Microarray::Dataset object and produces the images based on the meta
# data contained in the dataset object.  It is meant to separate the
# image production code into something a little more manageable.
#
# Usage:
# 
#   $imageMaker = Microarray::DatasetImageMaker(dataset=>$dataSetObj);
#
# where $dataset is an CdtDataset object class or another concrete
# Dataset class..
#
# Future Plans: This class should definitely be augmented to make
# images based on the various tree files


use strict;
use GD;
use File::Basename;
use vars qw($VERSION $dbg);

use Microarray::Config;

$VERSION = "0.1";

my $PACKAGE       = 'Microarray::DatasetImageMaker';
my $kImgType      = $PACKAGE.'::__imgType';
my $kDataset      = $PACKAGE.'::__dataset';
my $kContrast     = $PACKAGE.'::__contrast';
my $kColorScheme  = $PACKAGE.'::__colorScheme';
my $kName         = $PACKAGE.'::__name';
my $kImagePath    = $PACKAGE.'::__imagePath';
my $kDataPath     = $PACKAGE.'::__dataPath';
my $kHeight       = $PACKAGE.'::__height';
my $kWidth        = $PACKAGE.'::__width';

my %kColorSchemeTranslation = Microarray::Config->ColorSchemeTranslationHash;


# debug
$dbg = 0;


#####################################################################
sub new {
#####################################################################
# this is jsut a simple constructor, returning a DatasetImageMaker

    my $class = shift;
    my $self  = { };
    bless ($self, $class);

    $self->__setImageType();

    return $self;

}


#####################################################################
sub __setImageType {
#####################################################################
# 

    my $self = shift;

    $self->{$kImgType} = Microarray::Config->ImageType;

}

#####################################################################
sub imageType {
#####################################################################
# returns the suffix for the image type being used for a newly
# constructed dataset

    return $_[0]->{$kImgType};
}

#####################################################################
sub _dataset {
#####################################################################
# returns the dataset object used to initialize the imageMaker, if any

    return $_[0]->{$kDataset};
}


#####################################################################
sub _contrast {
#####################################################################
# returns contrast used initialize the imageMaker, either belonging to
# the dataset or other optional argument

    my $self = shift;

    if (!$self->{$kContrast} && ($self->_dataset)) {

	$self->{$kContrast} = $self->_dataset->contrast;

    }

    return $self->{$kContrast};
}


#####################################################################
sub _name {
#####################################################################
# returns file base name of the dataset used initialize the
# imageMaker, either belonging to the dataset or other optional
# argument

    my $self = shift;
    if (!$self->{$kName} && ($self->_dataset)) {
	$self->{$kName} = $self->_dataset->fileBaseName;
    }
    return $self->{$kName};
}


#####################################################################
sub _imagePath {
#####################################################################
# returns image outpath of the dataset used initialize the imageMaker,
# either belonging to the dataset or other optional argument

    my $self = shift;
    if (!$self->{$kImagePath} && ($self->_dataset)) {

	$self->{$kImagePath} = $self->_dataset->imagepath;
    }
    return $self->{$kImagePath};
}


#####################################################################
sub _dataPath {
#####################################################################
# returns data outpath of the dataset used initialize the imageMaker,
# either belonging to the dataset or other optional argument

    my $self = shift;
    if (!$self->{$kDataPath} && ($self->_dataset)) {

	$self->{$kDataPath} = $self->_dataset->datapath;
    }
    return $self->{$kDataPath};
}


#####################################################################
sub _height {
#####################################################################
# returns height of the dataset used initialize the imageMaker, either
# belonging to the dataset or other optional argument

    my $self = shift;
    if (!$self->{$kHeight} && ($self->_dataset)) {
	$self->{$kHeight} = $self->_dataset->height;
    }
    return $self->{$kHeight};
}



#####################################################################
sub _width {
#####################################################################
# returns width used initialize the imageMaker, either belonging to
# the dataset or other optional argument

    my $self = shift;

    if (!$self->{$kWidth} && ($self->_dataset)) {

	$self->{$kWidth} = $self->_dataset->width;

    }

    return $self->{$kWidth};
}


#####################################################################
sub _colorscheme {
#####################################################################
# returns colorscheme used initialize the imageMaker, either belonging
# to the dataset or other optional argument

    my $self = shift;

    if (!$self->{$kColorScheme} && ($self->_dataset)) {

	$self->{$kColorScheme} = $self->_dataset->colorScheme;

    }

    return $self->{$kColorScheme};
}



#####################################################################
sub _load_image {
#####################################################################
#
    my $self = shift;
    my $filename = shift;

    open(IN, $filename) || die "cannot open $filename! $!\n";

    my $funcname = "newFrom".ucfirst($self->imageType);

    my $image = GD::Image->$funcname(\*IN);

    close(IN);

    return $image;

}

#####################################################################
sub __checkAndSetDataset {
#####################################################################
# does some quick check on the dataset object being passed and sets it
# as a known attribute

    my $self = shift;
    my %args = @_;

    if (ref($args{'dataset'}) =~ m/Dataset/) {

	# they must pass a dataset argument and it must be some kind
	# of dataset (attempting a little flexibility, here (MAGE-ML
	# dataset, cdt dataset, generic dataset, etc...))

	$self->{$kDataset} = $args{'dataset'};

    }else{

	die "$PACKAGE requires a valid Dataset object, passed in by named argumnt";
    }

    return;

}


#####################################################################
sub makeImage {
#####################################################################
# this is the major method of DatasetImageMaker which produces the
# images.  It takes two named arguments, a CdtDataset arguement
# ('dataset') and an image type ('type').  Current known types are
# 'matrix' and 'header'
#
# Usage:
#      $imageMaker->makeImage(dataset=>$ds,
#                             type=>'matrix');

    my $self = shift;
    my %args = @_;

    $self->__checkAndSetDataset(%args);

    my $type = $args{'type'};

    # make a matrix image
    if ($type eq "matrix") {
	# load data matrix 
	$self->_load_matrix();

	print "Updating Image data with contrast of ".$self->_contrast." and colorscheme ".$self->_colorscheme." ...\n";

	my $contrast  = $self->_contrast;
	my $colscheme = $self->_colorscheme;

	# generate matrix gif
	$self->_makeMatrixImage( $contrast, $colscheme );

    }elsif($type eq "header") {

	# make experiment names image
	$self->_makeExptImage();

    }else{

	print "Unknown image type passed to $PACKAGE->makeImage.  Known types are matrix and header.\n\n"; }

    return;
}


#####################################################################
sub _load_matrix {
#####################################################################

    my $self = shift;

    my ($matrix, $index);

    my $filename = $self->_dataPath.$self->_name.".data_matrix";

    $matrix = [ ];

    open(IN, $filename) || die "cannot open _matrix_ $filename $!\n";

    while (<IN>) {

	chomp;
	my @row   = split("\t", $_, -1);
	$index = shift @row;

	$$matrix[$index] = \@row;	
	
    }

    $self->{MATRIX} = $matrix;

}



#####################################################################
sub _makeMatrixImage {   # Perl version of GIF generation
#####################################################################
#
    
    my $self = shift;

    my $contrast = shift;    # the contrast value to use
    my $color    = shift;    # the color scheme to use

    printf "cols: %s\n", $color;

    my $outdir   = $self->_imagePath;    # where to write image file
    my $name     = $self->_name;            # name of the image file
    my $aref     = $self->{MATRIX};         # reference to an array of tab delimited rows of the data matrix

    my $num_rows    = $self->_height;
    my $num_columns = $self->_width;  # subtract one, because the first value in row is index number, not data

    my $bm_width  = $num_columns;
    my $bm_height = $num_rows;

#    my $color = 0;
    my $missing_value = 80;
    
    my %colors;
    
    my $image = new GD::Image($bm_width,$bm_height);       # create a new bitmap the size of the matrix
    
    $colors{grey}  = $image->colorAllocate($missing_value, $missing_value, $missing_value);
    $colors{black} = $image->colorAllocate(0,0,0);              # first color allocated becomes background
    $colors{white} = $image->colorAllocate(255,255,255);

    # translating to a controlled parameter names
    $color = $kColorSchemeTranslation{$color};

    if ($color eq "rg") { # red green
	$colors{red}   = $image->colorAllocate(255,0,0);
	$colors{green} = $image->colorAllocate(0,255,0);
    } elsif ($color eq "yb") { # yellow blue
	$colors{red}   = $image->colorAllocate(255,255,0);
	$colors{green} = $image->colorAllocate(0,0,255);	
    }

    &_shadeAllocate($image, \%colors, $color);
    
    for(my $y=0; $y<=$num_rows; $y++) {
	
	for (my $x=0; $x<=$num_columns; $x++) {

#	    my $color = _get_log_color( $self->getMatrixValue($x,$y), $contrast, \%colors );	    
	    my $color = _get_log_color( $self->{MATRIX}[$y][$x], $contrast, \%colors );	    
# modified for direct access to save extra method call for each pixel

	    $image->setPixel($x, $y, $color);
	}
	
	if ( !( $y % 100 ) ) 
	{
	    print "row $y\n" if ($dbg) ;
	}

    }
    
    # print the MATRIX image
    
    open (MATRIX, ">$outdir$name.data_matrix.".$self->imageType) || die($!);
    binmode MATRIX;
    print MATRIX ($self->imageType eq "gif" ? $image->gif : $image->png);
    close MATRIX;

    print "saving image as ".$self->imageType."\n" if ($dbg) ;

    return; 
        
}


#####################################################################
sub _makeExptImage {
#####################################################################
#

    my $self = shift;

    my $outdir = $self->_imagePath();
    my $name   = $self->_name();

    my $line_number    = $self->_width;  # = number of items in list
    my $line_maxlength = 0;
    my $font_height    = 10;   # tiny
    my $font_width     = 5;
##    my $font_height = 13;     # small
##    my $font_width = 7;
##    my $font = "gdTinyFont";   # not used, see below

    my $bm_width       = 0;
    my $bm_height      = 0;
    my $white;
    my $black;
    my $i = 0;

    $line_number = 0;
    
    my @expts;

    # Should definitely investigate the use of something public, or
    # write a new accessor for experiment names instead of being
    # forced to use private method of the CdtDataset, like so...
#    my $exptNamesRef = $self->_dataset->__cdtFileObject->columnNamesArrayRef;
    
    for (my $i=0;$i<$self->_width();$i++) {
	# trying it here, but this seems a little cludgy...
	push (@expts, $self->_dataset->experiment($i, 'NAME'));
#	push @expts, $$exptNamesRef[$i]; # above line replaces this
    }
	
    foreach my $line ( @expts ) {
	if (length($line) > $line_maxlength) {
	    $line_maxlength = length($line);
	}
	$line_number++;
    }
    
    $bm_width  = ($font_height * ($line_number) );
    $bm_height = ($font_width * ($line_maxlength+1) );

    my $nameGif = new GD::Image($bm_width, $bm_height);
    
    $white = $nameGif->colorAllocate(255,255,255);
    $black = $nameGif->colorAllocate(0,0,0);

    foreach $name ( @expts ) {
	$nameGif->stringUp(gdTinyFont, ($i * $font_height)+1, $bm_height - 3, $name, $black);
	$i++;
    }

    open (HEADER, ">$outdir$name.expt_info.".$self->imageType) || die($!);
    binmode HEADER;
    print HEADER ($self->imageType eq "gif" ? $nameGif->gif : $nameGif->png);
    close(HEADER);
    
}


#####################################################################
sub _get_log_color {
#####################################################################
#

    my $logratio = shift;
    my $contrast = shift;
    my $colors = shift;     # shade container

    if ( !defined($logratio) || $logratio eq "" ) {
	return $$colors{grey};
    }

    my $converted_logratio = int(($logratio/$contrast)*124);
    
    if ( $converted_logratio == 0) {
	return $$colors{black};
    }
    
    if ($logratio > 0) {  # red hue
	
	if ($logratio >= $contrast) { # bigger then contrast, return brightest red
	    return $$colors{red};
	} else {
	    return $$colors{reds}[ $converted_logratio ];
	}

    } else {  # green hue

	if (abs($logratio) > $contrast) { # bigger then contrast, return brightest green
	    return $$colors{green};
	} else {
	    return $$colors{greens}[ $converted_logratio ];
	}
    }

} # end get_log_color


#####################################################################
sub _shadeAllocate {
#####################################################################
#

    my $image       = shift;
    my $colors      = shift;   # hashref

    my $colscheme   = shift;

    my (@shade_green, @shade_red);

    if ($colscheme eq "rg") {
	for(my $shade=0;$shade<124;$shade++) 
	{
	    $shade_green[124-$shade] = $image->colorAllocate(0,($shade*2),0);
	    $shade_red[$shade]       = $image->colorAllocate(($shade*2),0,0);
	}
    } elsif ($colscheme eq "yb") {
	for(my $shade=0;$shade<124;$shade++) 
	{
	    $shade_green[124-$shade] = $image->colorAllocate(0,0,($shade*2));
	    $shade_red[$shade]       = $image->colorAllocate(($shade*2),($shade*2),0);
	}
    }

    $$colors{reds}   = \@shade_red;
    $$colors{greens} = \@shade_green;

}



1;


__END__

#####################################################################
#
#  POD Documentation from here on down
#
#####################################################################

=pod

=head1 Name

Microarray::DatasetImageMaker - Creates an image from a microarray dataset

=head1 Abstract

Microarray::DatasetImageMaker is a class that accepts a
Microarray::Dataset object and produces the images based on the meta
data contained in the dataset object.  It is meant to separate the
image production code into something a little more manageable.


=head1 Usage

  $imageMaker = Microarray::DatasetImageMaker(dataset=>$dataSetObj);

where $dataset is an CdtDataset object class or another concrete
Dataset class.

=head1 Future Plans

This class should definitely be augmented to make images based on the
various tree files


=head1 Instance Constructor

=head2 new

my $imageMaker = Microarray::DatasetImageMaker->new();

=head1 Instance Methods

=head2 imageType

returns the suffix for the image type being used for a newly
constructed dataset

=head2 makeImage

This method actually results in an image being made.

Usage:

    $imageMaker->makeImage('dataset' => $self,
			   'type'    => 'matrix');
    $imageMaker->makeImage('dataset' => $self,
			   'type'    => 'header'); 

=head1 Protected Methods

=head2 _dataset

returns the dataset object used to initialize the imageMaker, if any

=head2 _contrast

returns contrast used initialize the imageMaker, either belonging to
the dataset or other optional argument

=head2 _name

returns file base name of the dataset used initialize the imageMaker,
either belonging to the dataset or other optional argument

=head2 _imagePath

returns image outpath of the dataset used initialize the imageMaker,
either belonging to the dataset or other optional argument

=head2 _dataPath

returns data outpath of the dataset used initialize the imageMaker,
either belonging to the dataset or other optional argument

=head2 _height

returns height of the dataset used initialize the imageMaker, either
belonging to the dataset or other optional argument

=head2 _width

returns width used initialize the imageMaker, either belonging to the
dataset or other optional argument

=head2 _colorscheme

returns colorscheme used initialize the imageMaker, either belonging
to the dataset or other optional argument

=head1 Authors

John C. Matese
jcmatese@genome.stanford.edu

=cut
