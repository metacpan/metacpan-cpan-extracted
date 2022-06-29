#!/usr/bin/env perl

#*******************************************************************************
##                           COPYRIGHT NOTICE
##      (c) 2019 The Johns Hopkins University Applied Physics Laboratory
##                         All rights reserved.
##
##  Permission is hereby granted, free of charge, to any person obtaining a 
##  copy of this software and associated documentation files (the "Software"), 
##  to deal in the Software without restriction, including without limitation 
##  the rights to use, copy, modify, merge, publish, distribute, sublicense, 
##  and/or sell copies of the Software, and to permit persons to whom the 
##  Software is furnished to do so, subject to the following conditions:
## 
##     The above copyright notice and this permission notice shall be included 
##     in all copies or substantial portions of the Software.
##
##  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
##  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
##  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
##  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
##  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
##  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
##  DEALINGS IN THE SOFTWARE.
##
#*******************************************************************************/

=head1 SYNOPSIS

Nuggit file rename wrapper.  This invokes "git mv" appropriately for the given file", which in turn renames said file and stages it in a single step.

WARNING: This command can only be used to move a file WITHIN a given submodule.  It is not possible to move a file between submodules while preserving history.

=cut

use strict;
use warnings;
use v5.10;
use Getopt::Long;
use Cwd qw(getcwd);
use Pod::Usage;
use Git::Nuggit;
use File::Spec;

my $ngt = Git::Nuggit->new(); # Initialize Nuggit & Logger prior to altering @ARGV
my $verbose = 0;
my ($help, $man);
Getopt::Long::GetOptions(
    "help"             => \$help,
    "man"              => \$man,
    "verbose"          => \$verbose,
    );
pod2usage(-exitval => 0, -verbose => 2) if $man;
pod2usage(1) if $help || !defined($ARGV[0]);

die("Not a nuggit!\n") unless $ngt;
$ngt->start(level => 1, verbose => $verbose); # Open Logger for loggable-command mode


my $file = $ARGV[0];
my $newfile = File::Spec->rel2abs($ARGV[1]);
say "Renaming $file to $newfile";

# Get name of parent dir
my ($vol, $dir, $fn) = File::Spec->splitpath( $file );

if ($dir) {
    chdir($dir) || die ("Error: Can't enter file's parent directory: $dir");
}
$ngt->run("git mv $fn $newfile");
