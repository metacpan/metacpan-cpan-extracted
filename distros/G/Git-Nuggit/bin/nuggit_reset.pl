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

use strict;
use warnings;
use v5.10;
use File::Spec;
use Getopt::Long;
use Cwd qw(getcwd);
use Pod::Usage;
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;
use Git::Nuggit::Status;
use Git::Nuggit::Log;

=head1 SYNOPSIS

A wrapper for a simplified subset of "git reset" functionality.  The following uses are supported:

Unstage a given file (or all staged files/objects):

- ngt reset [-p | -q] <paths>

=over

=item  -p | --patch  

Interactively select the sections of a file to un-stage.

=item -q | --quiet | --no-quiet

If set, only errors will be output. 


For other use cases, git reset must be executed manually at each desired level, or (with caution) using "ngt foreachgit reset".  For example, "ngt foreach git reset HEAD".  Due to the nature of submodules, commands such as resetting to HEAD~1 are NOT supported by nuggit.  

Additional use cases may be added in the future.  For example, a "ngt reset HEAD~1" would execute the equivalent git command at the root level only, followed by a 'git submodule update --init --recursive'.

=back

=cut

my $patch_flag = 0;
my $quiet_flag = 0;
my $mode = "";

my ($root_dir, $relative_path_to_root) = find_root_dir();
my $log = Git::Nuggit::Log->new(root => $root_dir);

ParseArgs();
die("Not a nuggit!") unless $root_dir;
$log->start(1);

my $cwd = getcwd();

my $base_cmd = "git reset ";
$base_cmd .= "-q " if $quiet_flag;
$base_cmd .= "-p " if $patch_flag;

my $argc = @ARGV; # get the number of arguments

if ($argc == 0) {
    say "No arguments specified, unstaging all";
    # NOTE: This is a simple implementation. We could optimize this by only running in submodules showing changes
    submodule_foreach(sub {
        system($base_cmd);
        $log->cmd($base_cmd);
                      });

} else {
    # For each given path
    foreach my $arg (@ARGV)
    {        
        say "Unstaging $arg";

        # Start at original working dir
        chdir($cwd);

        # Get name of parent dir
        my ($vol, $dir, $file) = File::Spec->splitpath( $arg );

        # Enter it. We do not currently handle case where parent dir was deleted (TODO)
        if ($dir) {
            chdir($dir) || die ("Error: $dir doesn't exist");
        }
        
        my $cmd = "$base_cmd $file";
        system($cmd);
        $log->cmd($cmd);
        
    }
}


sub ParseArgs
{
    my ($help, $man);
    Getopt::Long::GetOptions(
                           "quiet|q!"  => \$quiet_flag,
                           "patch|p!"  => \$patch_flag,
                           "help"            => \$help,
                           "man"             => \$man,
                          );
    pod2usage(1) if $help;
    pod2usage(-exitval => 0, -verbose => 2) if $man;
}
