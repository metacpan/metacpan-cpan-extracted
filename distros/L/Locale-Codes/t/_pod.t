#!/usr/bin/perl

use warnings 'all';
use strict;

BEGIN {
   use Test::More;
   # Don't run tests for installs
   unless ($ENV{Locale_Codes_RELEASE_TESTING}) {
      plan skip_all => 'Author tests not required for installation (set Locale_Codes_RELEASE_TESTING to test)';
   }
}

# CPANTORPM-DEPREQ REQEXCL File::Basename
# CPANTORPM-DEPREQ REQEXCL Cwd
# CPANTORPM-DEPREQ REQEXCL Test::Pod

use File::Basename;
use Cwd 'abs_path';
use Test::Pod 1.00;

# Figure out the directories.  This comes from Test::Inter.

my($moddir,$testdir,$libdir);

BEGIN {
   if (-f "$0") {
      $moddir = dirname(dirname(abs_path($0)));
   } elsif (-d "./t") {
      $moddir = dirname(abs_path('.'));
   } elsif (-d "../t") {
      $moddir = dirname(abs_path('..'));
   }
   if (-d "$moddir/t") {
      $testdir = "$moddir/t";
   }
   if (-d "$moddir/lib") {
      $libdir = "$moddir/lib";
   }
}

# If there is a file _pod.ign, it should be a list of filename
# substrings to ignore (any file with any of these substrings
# will be ignored).
#
# If there is a file named _pod.dirs, then pod files will be looked
# at in those directories (instead of the default of all directories).

my @ign = ();
if (-f "$testdir/_pod.ign") {
   open(IN,"$testdir/_pod.ign");
   @ign = <IN>;
   close(IN);
   chomp(@ign);
}

my @dirs = ();
if (-f "$testdir/_pod.dirs") {
   open(IN,"$testdir/_pod.dirs");
   @dirs = <IN>;
   close(IN);
   chomp(@dirs);
}

#
# Test that the syntax of our POD documentation is valid.
#

chdir($moddir);

if (@ign) {

   my @file = all_pod_files(@dirs);
   my @test;

   FILE:
   foreach my $file (@file) {
      foreach my $ign (@ign) {
         next FILE  if ($file =~ /\Q$ign\E/);
      }
      push(@test,$file);
   }

   plan tests => scalar(@test);
   foreach my $file (@test) {
      pod_file_ok($file);
   }

} else {
   all_pod_files_ok(@dirs);
}
