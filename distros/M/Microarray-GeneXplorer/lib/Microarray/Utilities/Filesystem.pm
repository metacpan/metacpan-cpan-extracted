package Microarray::Utilities::Filesystem;

use strict;
use File::Basename;


use vars qw (@ISA @EXPORT_OK);
use Exporter;
@ISA = ('Exporter');
@EXPORT_OK = qw( DirectoryIsValid EnsureTrailingSlash);

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


###############################################################################
sub DirectoryIsValid {
###############################################################################
# this subroutine takes a single argument, a directory path, and
# simply returns it if it passes that validation rules below

    my $dir = shift;

    return(0) unless (-d $dir);  # Fail (Skip) everything but directories that are
    return(0) unless (-r $dir);  #   readable and
    return(0) unless (-x $dir);  #   executable.
    return(0) if $dir =~ m/RCS/; # skip RCS directories
    return(0) if $dir =~ m/CVS/; # skip CVS directories

    return 1; # return the directory name, validated as true

}


###############################################################################
sub EnsureTrailingSlash {
###############################################################################
# this subroutine takes a single argument, a string represent a file
# path, and simply ensures that is has a trailing slash (adds it if
# necessary)

    my $path = shift;

    if ($path !~ /\/$/){

	$path .= '/';

    }

    return $path; # return the filepath

}


1; # to make perl happy
