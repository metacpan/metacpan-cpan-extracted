package Microarray::Config;

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


# This package is to be used by microarray softare for the GMOD
# project, to get file paths and other configurations, so that
# programs can be easily be moved about


use strict;

my $VERSION = "0.1";

my $PACKAGE = 'Microarray::Config';

my $kRootPath      = $PACKAGE.'::__serverPath';
my $kBinPath       = $PACKAGE.'::__binPath';
my $kRootURL       = $PACKAGE.'::__serverUrl';
my $kTmpPath       = $PACKAGE.'::__tmpPath';
my $kTmpURL        = $PACKAGE.'::__tmpURL';
my $kGxHtmlPath    = $PACKAGE.'::__gxHtmlPath';
my $kGxImagesPath  = $PACKAGE.'::__gxImagesPath';
my $kGxDataPath    = $PACKAGE.'::__gxDataPath';
my $kGxURL         = $PACKAGE.'::__gxURL';
my $kGxImagesURL   = $PACKAGE.'::__gxImagesURL';
my $kDataPath      = $PACKAGE.'::__dataPath';
my $kHtmlPath      = $PACKAGE.'::__htmlPath';
my $kGxRootWord    = $PACKAGE.'::__gxRootword'; # just to store a key directory name


#########################################################################
sub new{
#########################################################################
# This simple constructor initializes a few variables, and returns a
# object reference, which can then be used to call the various methods
#
# Microarray::Config makes some very strict assumptions about the layout of the
# file system.  It assumes you will provide it a rootpath, and a rooturl, and that below
# the rootpath will be the following directories:
#
# html, html/tmp, html/explorer, html/images, data, data/explorer, bin
#
# it assumes that the rooturl points to the rootpath/html/
#
#
#  Usage my $config = Microarray::Config->new(rootpath => $rootpath,
#                                             rooturl  => $rooturl);
#  my $path = $config->gxHtmlPath;


    my $self = {};

    bless $self, shift;

    $self->__init(@_);

    return $self;

}


#########################################################################
sub __init {
#########################################################################

    my ($self, %args) = @_;

    # ROOTWORDS below
    $self->{$kGxRootWord} = 'explorer'; # key directory for explorer

    # FILEPATHS BELOW 
    $self->{$kRootPath} = $args{'rootpath'} || die "You must provide a rootpath";

    $self->{$kBinPath}  = $self->{$kRootPath}.'bin/';

    $self->{$kDataPath} = $self->{$kRootPath}.'data/';
    $self->{$kGxDataPath} = $self->{$kDataPath}.$self->{$kGxRootWord}.'/';

    $self->{$kHtmlPath}     = $self->{$kRootPath}.'html/';
    $self->{$kTmpPath}      = $self->{$kHtmlPath}.'tmp/';
    $self->{$kGxHtmlPath}   = $self->{$kHtmlPath}.$self->{$kGxRootWord}.'/';
    $self->{$kGxImagesPath} = $self->{$kGxHtmlPath}.'images/';


    # URLS BELOW 
    $self->{$kRootURL} = $args{'rooturl'} || die "You must supply a rooturl";
    $self->{$kTmpURL} = $self->{$kRootURL}.'/tmp/';
    $self->{$kGxURL} = $self->{$kRootURL}.'/'.$self->{$kGxRootWord}.'/';
    $self->{$kGxImagesURL} = $self->{$kGxURL}.'images/';

    return $self;
}

#########################################################################
#
#         ACCESSOR METHODS
#
#########################################################################
#########################################################################
sub serverRootPath {
#########################################################################

    return $_[0]->{$kRootPath};
}

#########################################################################
sub tmpPath{
#########################################################################
# This method returns the filepath of the tmp directory to be used by
# microarray cgi's

    return $_[0]->{$kTmpPath};
}

#########################################################################
sub gxHtmlPath {
#########################################################################
# returns the filesystem path to the explorer html directory stem,
# suitable for appending the project name and dataset name
# (directories)

    return $_[0]->{$kGxHtmlPath};
}


#########################################################################
sub gxImagesPath {
#########################################################################
# returns the filesystem path to the explorer images directory stem,
# home of those images accompanying the distribution

    return $_[0]->{$kGxImagesPath};
}


#########################################################################
sub gxDataPath {
#########################################################################
# returns the filesystem path to the explorer data directory stem,
# suitable for appending the project name and dataset name
# (directories)

    return $_[0]->{$kGxDataPath};
}


#########################################################################
sub binPath{
#########################################################################
# This method returns the path of the directory contianing the binary
# scripts


    return $_[0]->{$kBinPath};
}


#########################################################################
sub tmpUrl{
#########################################################################
# This method returns the URL of the tmp directory to be used by
# microarray cgi's

    return $_[0]->{$kTmpURL};
}


#########################################################################
sub gxRootWord {
#########################################################################

    return $_[0]->{$kGxRootWord};
}



#########################################################################
sub gxURL {
#########################################################################
# returns the stem URL for the explorer documents, suitable for appending
# the project name and dataset name (directories)

    return $_[0]->{$kGxURL};
}


#########################################################################
sub gxImagesURL {
#########################################################################
# returns the stem URL for the explorer images, including scalebars,
# background images, and other images included within the distribution

    return $_[0]->{$kGxImagesURL};
}

#########################################################################
sub ColorSchemeTranslationHash {
#########################################################################
# This public class method returns a colorscheme lookup hash, so that
# the myriad of user imput, client software, and class expectations
# can be tranlated to a simple, standardized two letter code for the
# colorscheme.  This could be added to in the future, if required.

    return ('red/green'   =>'rg',
	    'green/red'   =>'rg',
	    'rg'          =>'rg',
	    'gr'          =>'rg',
	    'blue/yellow' =>'yb',
	    'yellow/blue' =>'yb',
	    'yb'          =>'yb',
	    'by'          =>'yb');

}


#########################################################################
sub ImageType {
#########################################################################
# this public class simply return the type of image that is likely
# being written by GD, based on the GD version

    my $kImgType = ($GD::VERSION > 1.19) ? "png" : "gif";

    return $kImgType;

}

1;
