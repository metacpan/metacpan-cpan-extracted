#!/usr/bin/perl

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


# Description: makeMicroarrayDataset.pl is an example client script of
# Microarray::CdtDataset.  It takes a input a microarray project
# datafile (currently .cdt format, although in the future other known
# formats(e.g. MAGE-ML/XML) might be included.

use strict;
use Getopt::Long;


use Microarray::Config;
use Microarray::CdtDataset; 
use Microarray::Utilities::Filesystem qw(DirectoryIsValid EnsureTrailingSlash);

#########################################################################
#
# MAIN
#
#########################################################################

# First we simply deal with getting and checking command line arguments

if (!@ARGV) { &Usage }

# the following are the default options for making a dataset that will
# be utilized by getopts and then passed to the CdtDataset constructor

my ($filepath, $name, $verbose, $rootpath, $help); # undef by default

# defaults for this client
my $contrast    = 4;
my $colorscheme = 'yellow/blue';
my $corrcutoff  = 0.5;

my %args = (contrast     => \$contrast,
	    colorscheme  => \$colorscheme,
	    corrcutoff   => \$corrcutoff,
	    name         => \$name,
	    rootpath     => \$rootpath,
	    verbose      => \$verbose,
	    file         => \$filepath,
	    help         => \$help);


unless(&GetOptions( \%args, "name=s", "file=s", "rootpath=s", "contrast=f", "colorscheme=s", "corrcutoff=f", "verbose", "help")){
    &Usage;
}

if ($verbose) { 
    print "Creating new dataset, $name, from file $filepath...\n";
}

&Usage if($help);

die "Requested <rootpath> path, $rootpath doesn't exist."   if (!&DirectoryIsValid($rootpath));

# if we get here, we have everything we need to try and create a dataset

# first create a Microarray::Config object

# we just pass it a dummy root url, as we know it's not needed during
# dataset construction - not a really good solution, but this is what
# I'm reduced to when hacking other people's code...

my $config = Microarray::Config->new(rootpath => $rootpath,
				     rooturl  => 'blah');

# now create a Microarray::CdtDataset, which will take care of all the
# details to actuallt create the files that underlie a dataset

my $ds = Microarray::CdtDataset->new(name        => $name,
				     contrast    => $contrast,
				     colorscheme => $colorscheme,
				     corrcutoff  => $corrcutoff,
				     datapath    => $rootpath.'/data/explorer/',
				     imagepath   => $rootpath.'/html/explorer/',
				     initialize  => $filepath,
				     verbose     => $verbose,
				     config      => $config);

if ($args{verbose}) { 
    print "Successfully created new dataset object ".$ds->name."\n";
    print "Data are created in ".$ds->datapath."\n"; 
    print "Images are created in ".$ds->imagepath."\n"; 
}

exit;

#########################################################################
sub Usage {
#########################################################################

    print STDOUT <<EOF;

  Usage:

$0 -file <file/name> -name <intended/dataset/name> [-dataout <repository_directory> -imageout <image directory> -contrast <float> -colorscheme <rg|yb> -corrcutoff <float> -verbose]

    -----------------------------------------------------------------------------

    -file        = required input file (currently only '.cdt' files supported)

    -name        = required dataset name to be created
	           (may be delimited by slashes(/) to imply hierarchy)

    -rootpath    = required root directory, under which must exist html
		   and data directories

    -contrast    = optional contrast value for the generated images
                   (defaults to 4, As the data are expected to be in
                   log base 2, this corresponds to a 16-fold change as
                   the maximum color in any image)

    -colorscheme = optional color scheme used for generating the images
	           (rg = red/green, yb = yellow/blue ; defaults to yellow/blue)

    -corrcutoff  = optional value for correlation cutoff during dataset creation
                   (defaults to 0.5 if not specified; allowed range: 0.2 - 1.0)

    -verbose     = show feedback messages during run

EOF

    exit;

}


