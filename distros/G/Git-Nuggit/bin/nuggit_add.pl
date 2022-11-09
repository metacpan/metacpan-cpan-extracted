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
use Term::ANSIColor;

# usage: 
#
# nuggit_add.pl <path_to_file>
#
# NOTE: Branch consistency check is not required for add, but should run as a pre-commit hook.

my $cwd = getcwd();
my $add_all_bool = 0;
my $patch_bool = 0;
my $ngt = Git::Nuggit->new("run_die_on_error" => 0);

my $root_dir = $ngt->root_dir();
die("Not a nuggit!") unless $root_dir;
my $log = Git::Nuggit::Log->new(root => $root_dir);

ParseArgs();
$ngt->start(level=>1);

chdir($cwd);


my $argc = @ARGV;  # get the number of arguments.
  
if ($argc == 0) {
    chdir($root_dir);
    # This is only valid if -A flag was set
    if ($add_all_bool) {
        # Run "git add -A" for each submodule that has been modified.
        add_all();
    } else {
        say colored("Error: No files specified",'error');
        pod2usage(1);
    }
} else {

    foreach(@ARGV)
    {
        add_file($_);
        
        # ensure that we are still at the same starting directory as when the caller
        # called this script.  This is important because all of the paths passed in
        # are relative to it.
        chdir $cwd;
    }
}


sub ParseArgs
{
    my ($help, $man);
    Getopt::Long::GetOptions(
                           "all|A!"  => \$add_all_bool,
                           "patch|p!"  => \$patch_bool,
                           "help"            => \$help,
                           "man"             => \$man,
                          );
    pod2usage(1) if $help;
    pod2usage(-exitval => 0, -verbose => 2) if $man;
}

sub add_all
{
    $ngt->foreach(sub {
                          my $in = shift;
                          
                        
                        my ($err, $stdout, $stderr) = $ngt->run("git add --all");

                        if ($err) {
                            say colored("Failed to add all in $in->{subname}.  Git reports;", 'error');
                            say $stdout;
                        }
                    });
}


sub add_file
{
  my $relative_path_and_file = $_[0];
  
  say colored("Adding file $relative_path_and_file", 'info');

  my ($vol, $dir, $file) = File::Spec->splitpath( $relative_path_and_file );

  if (-d $dir) {
      # Easy case
      chdir($dir);
      git_add($file);
  } else {
      # File may have been deleted or renamed.  We need to find the last path in $dir that is valid
      my @dirs = File::Spec->splitdir($dir);
      while(@dirs) {
          my $path = shift(@dirs); # Get first path from dir list
          if (-d $path) {
              chdir($path);
          } else {
              unshift(@dirs, $path); # Put it back for consistency
              last;
          }
      }
      $file = File::Spec->catfile(@dirs, $file);
      git_add($file);
  }
}

sub git_add {
    my $file = shift;
    my $cmd = "git add";
    $cmd .= " -p " if $patch_bool;
    $cmd .= " -A " if $add_all_bool;
    $cmd .= " $file" if $file; # support for -A option
    my ($err, $stdout, $stderr) = $ngt->run($cmd);

    if ($err) {
        say colored("Failed to add $file in ".getcwd().".  Git reports;", 'error');
        say $stdout;
    }
}

=head1 Nuggit add

Stage the specified file(s) in the repository, automatically handling submodule boundaries.

=head1 SYNOPSIS

Specify one or more files or directories to be added.  A file is required unless help, man, or -A is specified.

Examples: "nuggit_add.pl -A" or "nuggit_add.pl foo/bar" or "nuggit_add.pl -p README.md"

=over

=item --help

Display an abbreviated help menu

=item --man

Display detailed documentation.

=item -A | --all

Stage all uncommitted changes (excludes untracked and ignored files)

=item -p | --patch

Interactively select which segments of each file to stage.


=back


=cut
