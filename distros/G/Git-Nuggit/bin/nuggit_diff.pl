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

use Getopt::Long;
use strict;
use warnings;
use v5.10;
use Pod::Usage;
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;
use Term::ANSIColor;
use Cwd qw(getcwd);

=head1 SYNOPSIS
   No arguments - get all the differences between the working copy of 
      files and the local repository

 nuggit_diff.pl ../path/to/file.c
   One argument: Argument is a particular file, which may be in a submodule (or not) -
      get the differences of the specified file between the 
      working copy of the file and the local repository

 nuggit_diff.pl ../path/to/dir
   One argument: Argument is a particular directory, which may be in a submodule (or not) -
      get the differences of the specified directory between the 
      working copy of the file and the local repository

 nuggit_diff.pl origin/<branch> <branch>
   two arguments, diff between the two branches

The following options are supported:

=over

=item --color | --no-color

By default, all diff output is shown with ANSI terminal colors (--color).  If this is not desired, for example if saving output to a patch file, specify "--no-color" to disable.

=item --cached

If defined, show changes that have been staged.

=item --strategy ref|branch

Nuggit strategy to use when recursing into submodules.  The default mode is branch-first.

In ref-first mode, this is equivalent to "git diff --submodule=diff $obj", utilizing Git's native support for translating any submodule reference differences into their constituent changes.  WARNING: This mode will show changes in submodules based on the committed state (references), but does NOT typically reflect uncommitted changes in the working tree.

In branch-first mode, this is equivalent to executing "git diff $obj" in the root repository, and recursively for each submodule.  

NOTE: If all branch references are synchronized with their HEAD commits, the results should be equivalent with either strategy.


=back

=cut


sub ParseArgs();

my $strategy = 'branch';
my $verbose = 0;
my $arg_count = 0;
my $show_color = 1;
my $show_cached = 0;
my $root_dir;

my $filename;
my $path;

my $diff_object1 = "";
my $diff_object2 = "";

my $ngt = Git::Nuggit->new("echo_always" => 0, "run_die_on_error" => 0) || die("Not a nuggit");
$root_dir = $ngt->root_dir();


ParseArgs();
$ngt->start(level => 0);


if($arg_count == 0)
{
    chdir($root_dir);

    if ($strategy eq 'branch') {
        $ngt->foreach({'run_root' => 1, 'breadth_first' => sub {
                       my $info = shift;
                       my $parent = $info->{'parent'};
                       my $name = $info->{'name'};

                       if ($parent eq ".") {
                           do_diff($name);
                       } else {
                           do_diff("$parent/$name/");
                       }
                   }});
    } else {
        submodule_diff();
    }

}
elsif($arg_count == 1)
{
  # get the diff of one file
  say "Get the diff of one object: $diff_object1" if $verbose;

  if(-e $diff_object1)
  {
    say "$diff_object1 is a file or directory" if $verbose;

    my ($vol, $dir, $file) = File::Spec->splitpath( $diff_object1 );
    if ($dir) {
        # If file is in a sub-directory, chdir first to ensure we are in correct repository
        chdir($dir) || die "$dir is not a directory";
    }
    do_diff($dir, $file);

  }
  else
  {
      # TODO: Validate argument as branch, or diff between branches.
      # Future: SHA1 diffs would have to follow submodule references

      chdir($root_dir);

      if ($strategy eq 'branch') {
          $ngt->foreach({
              'recursive' => 1,
              'run_root' => 1,
              'breadth_first' => sub {
                  my $in = shift;
                  do_diff($in->{'subname'}, $diff_object1);
                  }
              });
      } else {
          submodule_diff($diff_object1);
      }
  }
}
elsif($arg_count == 2)
{

    # when two arguments are provided, assume these are branches
    die "Two argument diff format not currently supported. If you intended to compare two objects, use the alternate git syntax of 'ngt diff obj1...obj2'\n";

}



sub ParseArgs()
{
  my ($help, $man, $tmp_branchfirst, $tmp_reffirst);
  # Gobble up any know flags and options

  Getopt::Long::GetOptions(
      "help"            => \$help,
      "man"             => \$man,
      "verbose!"        => \$verbose,
      "color!"          => \$show_color,
      "cached!"         => \$show_cached,
      "strategy|s=s"      => \$strategy,
      "branch-first!"   => \$tmp_branchfirst,
      "ref-first!"      => \$tmp_reffirst,
     );
  pod2usage(1) if $help;
  pod2usage(-exitval => 0, -verbose => 2) if $man;

  $strategy = 'branch' if $tmp_branchfirst;
  $strategy = 'ref' if $tmp_reffirst;
  die "Strategy must be 'branch' or 'ref'\n" if $strategy ne 'branch' && $strategy ne 'ref';

  $arg_count = @ARGV;

  if ($show_color) {
      eval {
          BEGIN {
              $ENV{LESS} = "-R"; # If less is available, make sure we tell it to parse ANSI color codes
          }
          require IO::Page;
      };
  }

  if($arg_count >= 1)
  {
    $diff_object1 = $ARGV[0];
  }

  # if there is another arg, is it the thing to diff against?
  if($arg_count > 1)
  {
     $diff_object2 = $ARGV[1];
  }

}

sub do_diff
{
    my $cmd = "git diff";
    $cmd .= " --color" if $show_color;
    $cmd .= " --cached" if $show_cached;
    my $rel_path = shift; # Always present
    my $args = shift; # Additional arguments (ie: file, directory, or object)
    $cmd .= " ".$args if $args;

    my ($err, $stdout, $stderr) = $ngt->run($cmd);

    # Normalize Paths
    if ($rel_path) {
        $rel_path .= '/' unless $rel_path =~ /\/$/;
        # We are in a sub-module, prepend dir, ie: replace "--- a/FILE" with "--- a/$rel_path/FILE"
        #  Note; Regex allows for optional ANSI escape sequences when diff includes colorization
        $stdout =~ s/^((\e\[\d+m)*((\+\+\+)|(\-\-\-))\s[ab]\/)/$1$rel_path/mg;
    } else {
        # At root level, no adjustment needed.
        # NOTE: We will always display paths relative to root for consistency in case user decides to use output as a patch file
    }
    if ($err) {
        # TODO: Consider suppressing output if error is that $rel_path doesn't exist (unless true at all levels)
        say colored("Failed to execute diff of $rel_path",'error');
    }

    say $stdout if $stdout;
    say $stderr if $stderr;
}

# Executive Native Git Diff, with submodule=diff flag
sub submodule_diff {
    my $diff_object1 = shift;
    my $cmd = "git diff --submodule=diff ";
    $cmd .= " --color " if $show_color;
    $cmd .= " --cached" if $show_cached;
    $cmd .= "$diff_object1" if $diff_object1;
    
    my ($err, $stdout, $stderr) = $ngt->run($cmd);
    say $stdout if $stdout;
    say $stderr if $stderr;
}
