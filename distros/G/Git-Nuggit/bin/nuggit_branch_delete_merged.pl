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

# This script is used to delete branches that have already been merged
# This operates on the local repository AND the the remote (central) repository

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
use Git::Nuggit::Log;


# usage: 
#
# nuggit_branch_delete_merged.pl <branch_to_delete>
#

sub ParseArgs();


my $argc = @ARGV;  # get the number of arguments.
my $cwd = getcwd();
my $branch_to_delete = "";

print "nuggit_branch_delete_merged.pl\n";


my ($root_dir, $relative_path_to_root) = find_root_dir();
die("Not a nuggit!") unless $root_dir;
my $log = Git::Nuggit::Log->new(root => $root_dir);

ParseArgs();
$log->start(1);

chdir($cwd);


if ($argc != 1) 
{
  print "Number of arguments: $argc\n";
  say "Error: No branch specified";
#  pod2usage(1);
  exit(0);
}
else
{

  print "TO DO - CLEAN THIS UP\n";
  print "TO DO - add nuggit log entry\n";

  print "TO DO - add error checking: make sure the currently checked out branch is NOT the branch to delete\n";
  print "TO DO - add error checking: make sure branch has been merged and does not contain commits that are not in master (on remote and local)\n";
  `nuggit branch -rd $branch_to_delete`;
  `nuggit branch -d  $branch_to_delete`;

  # this next command will remove local knowlege of the remote branch if the branch has been deleted remotely
  `git submodule foreach --recursive git fetch -p`;
  `git fetch -p`;
  

# TBD - in case the commands above fail and the branch has been partially 
#  deleted... (in some repos but not all)
#    The "|| :" at the end of the following commands means if there is an error do not abort and keep going on to the next submodule
#  `ngt foreach git push origin --delete $branch_to_delete || :`;
#  `ngt foreach git branch -d $branch_to_delete` || :;

}


sub ParseArgs()
{
  print "to do\n";
  $branch_to_delete = $ARGV[0];
  
  if($argc >= 1)
  {
    print "branch to delete is $branch_to_delete\n";
  }
}
