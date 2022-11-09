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

If executed without arguments, this script will simply list the known submodules.

This script provides a generic wrapper for commands (got or otherwise) to be executed as-is on each submodule, with all arguments passed along.  This is effectively a wrapper for "git submodule foreach" that invokes the command depth-first, ending with the root level.

Usage is:  "nuggit foreach [<opts>] -- <cmd> <args>".

NOTICE: Unlike "git submodule foreach", this script may NOT abort on first error, and WILL also be executed at the (nuggit) root level.

The following options are supported. Options must come before command and arguments.  If arguments include '-' or '--' prefixed arguments, you must provide a "--" delimeter to mark the end of arguments to this script.  

=over

=item --help

Display an abbreviated help menu

=item --man

Display detailed documentation.

=item --recursive | --no-recursive

Defaults to recursively executing on all nested submodules.

=item --break-on-error | --no-break-on-error

By default, operations will abort on the first command that fails. If this option is disabled, the specified command will be executed against all submodules, regardless of success.

=item --log_level

Determine Nuggit logging level.  If set to 0, then the executed command will not be logged.  Default value is 1, with full log results viewab le with "ngt log".  

=back

=cut

use strict;
use warnings;
use v5.10;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib $FindBin::Bin.'/../lib';
use Term::ANSIColor;
use Git::Nuggit;

# Modifier Arguments
my $break_on_error = 1; # If true, die on first child task to exit with a non-zero error code
my $recursive = 1;
my $run_root = 0;
my $verbose = 0;
my $breadth_first = 1; my $depth_first;
my $ngt = Git::Nuggit->new() || die("Not a nuggit!");
my $log_level = 1; # Set to 0 to disable logging
my ($help, $man);

# Parse Command-line arguments.  Arguments must be the first argument, and must end with a '--' if child args to follow
GetOptions(
           "help"            => \$help,
           "man"             => \$man,
           "verbose!"        => \$verbose,
           "break-on-error!" => \$break_on_error,
           "recursive!"      => \$recursive,
           "log_level=i"     => \$log_level,
           "breadth!"        => \$breadth_first,
           "depth!"          => \$depth_first,
           "root!"           => \$run_root,
          );
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;

$breadth_first = !$depth_first if defined($depth_first);

my $cmd = join(' ', @ARGV); # $Pass all remaining arguments on

if ($cmd ne '') {
    say "Nuggit Wrapper; $cmd";
} else {
    say 'Nuggit Submodule Listing:';
    say "\nParent\tName\tStatus\tHash\tLabel";
}
    
# Start at root Nuggit repo
my $root_dir = $ngt->root_dir();
$ngt->start(level => $log_level, verbose => $verbose);
$ngt->run_die_on_error($break_on_error);

chdir $root_dir || die("Error: Can't enter root; $root_dir");

$ngt->foreach({'recursive' => $recursive,
               'run_root' => $run_root,
               ($breadth_first ? 'breadth_first' : 'depth_first') => sub {
                   my $in = shift;
                   my ($parent, $name, $status, $hash, $label) = (@_);
                   if ($cmd ne '') {
                       say colored("$parent/$name - Executing $cmd", 'green');
                       $ngt->run($cmd);
                   } else {
                       say "$in->{parent}\t$in->{name}\t$in->{status}\t$in->{hash}\t$in->{label}";
                   }
               }
              });


if ($cmd ne '') {
    say colored("Root ($root_dir) - $cmd", 'green');
    system($cmd);
}

# Done
