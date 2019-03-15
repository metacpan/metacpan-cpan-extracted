#!/usr/bin/perl

use warnings 'all';
use strict;
use Test::More;
use File::Basename;
use Cwd 'abs_path';
use Test::Pod::Coverage 1.00;

# Don't run tests for installs
unless ($ENV{RELEASE_TESTING}) {
   plan skip_all => 'Author tests not required for installation (set RELEASE_TESTING to test)';
}

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
use lib $libdir;

# If there is a file _pod_coverage.ign, it should be a list of module
# name substrings to ignore (any module with any of these substrings
# will be ignored).

my @ign = ();
if (-f "$testdir/_pod_coverage.ign") {
   open(IN,"$testdir/_pod_coverage.ign");
   @ign = <IN>;
   close(IN);
   chomp(@ign);
}

#
# Test that the POD documentation is complete.
#

chdir($moddir);

if (@ign) {

   my @mod  = all_modules('lib');
   my @test = ();

   MOD:
   foreach my $mod (@mod) {
      foreach my $ign (@ign) {
         next MOD  if ($mod =~ /\Q$ign\E/);
      }
      push(@test,$mod);
   }

   chdir($libdir);
   plan tests => scalar(@test);
   foreach my $mod (@test) {
      pod_coverage_ok($mod);
   }

} else {
   all_pod_coverage_ok();
}
