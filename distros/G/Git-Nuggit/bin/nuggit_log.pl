#!/usr/bin/env perl

#*******************************************************************************
##                           COPYRIGHT NOTICE
##      (c) 2020 The Johns Hopkins University Applied Physics Laboratory
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

use Cwd qw(getcwd);

=head1 Nuggit log

Display the git log of the root repository.

=head1 SYNOPSIS

To compare ahead and behind commits between the current and a specified branch, use --diff and --all.  It is recommended pipe to more or less if -n is not used.

Example usage:
nuggit log
nuggit log -n <#>
nuggit log --diff <branch name>
nuggit log --diff --all <branch name>
nuggit log --diff --all <branch-name> -n <#> -p

=over

=item -n <#>

Specify the number of commits to show.

=item --diff <branch name>

Show the ahead commits; a branch name is required.

=item --all

Show the ahead and behind commits ; the diff flag and branch name are also required.

=item -p

Include patch text.

=cut

sub ParseArgs();
sub do_log();

my $verbose = 0;
my $arg_count = 0;
my $diff = 0;
my $all = 0;
my $n = 0;
my $p = 0;
my $root_dir;
my $diff_object = "";

# go to nuggit root
my $ngt = Git::Nuggit->new("echo_always" => 0);
$root_dir = $ngt->root_dir();
chdir($root_dir);


ParseArgs();
$ngt->start(level => 0);


sub ParseArgs()
{
  my ($help, $man);
  # Gobble up any known flags and options

  Getopt::Long::GetOptions(
   "help"             => \$help,
   "man"              => \$man,
   "verbose!"         => \$verbose,
   "diff!"            => \$diff,
   "all!"             => \$all,
   "n:i"              => \$n,
   "p!"               => \$p,
                          );
  pod2usage(1) if $help;
  pod2usage(-exitval => 0, -verbose => 2) if $man;

  $arg_count = @ARGV;
  print "Number of arguments $arg_count \n" if $verbose;

  print "N = $n\n";

  if($arg_count >= 1)
  {
    $diff_object = $ARGV[0];
  }

  if (not $diff) {
    if ($all) {
      # diff flag required with all
      die "--diff flag required with --all";
    }
    print "Default log";
    do_log();
  }
  else{
    if ($diff_object eq "") {
      # branch name required
      die "branch name required";
    }
    if ($all) {
      print "Variant 2\n";
    } else {
      print "Variant 1\n";
    }
    submodule_foreach(\&do_log);
  }
}

sub do_log()
{
  my $cmd = "git log";
  #$cmd .= (" -" . $n) if $n;
  $cmd .= " -p" if $p;

  # default log
  if (not $diff) {
    $cmd .= (" -" . $n) if $n;
    say $ngt->run($cmd . $diff_object);

  # diff
  } else {

    # get current branch name
     my ($err1, $branch, $stderr1) = $ngt->run("git rev-parse --abbrev-ref HEAD");

    # if there is no diff output, the ahead and behind counts will be 0
    my ($err, $stdout, $stderr) = $ngt->run("git diff " . $branch);
    if ($stdout) {

    # get ahead behind counts
     my ($err2, $ahead_behind, $stderr2) = $ngt->run("git rev-list --left-right --count " . $diff_object . "..." . $branch);
    $ahead_behind =~ s/(\d+)\s+(\d+)//;
    my $count = int($2) + ($all ? int($1) : 0);

    if ($count < $n) {
      $n = $count
    }

    # if n is not given it is the ahead (+ behind if --all) count
    if ($n == 0) {
      $n = int($2) + ($all ? int($1) : 0);
    }

    $cmd .= " -" . $n;

    # show commits
    if ($n > 0) {
      # show repo name
      use Cwd qw(cwd getcwd);
      my $currentDir = getcwd;
      my ($root_dir, $relative_path_to_root) = find_root_dir();
      my ($beforeMatch, $match) = split($root_dir, $currentDir);
      my @rootPath = split('/', $root_dir);
      my $rootName = $rootPath[$#rootPath];
      say $rootName . $match;

      say $ngt->run($cmd);
    }
  }
  }
}

