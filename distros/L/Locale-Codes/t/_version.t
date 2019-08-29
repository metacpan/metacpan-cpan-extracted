#!/usr/bin/perl

use warnings 'all';
use strict;
use Test::Inter;
my $ti;

BEGIN {
   $ti      = new Test::Inter $0;
   unless ($ENV{RELEASE_TESTING}) {
      $ti->skip_all('Author tests not required for installation (set RELEASE_TESTING to test)');
   }
}

# CPANTORPM-DEPREQ REQEXCL IO::File
# CPANTORPM-DEPREQ REQEXCL File::Find::Rule

use IO::File;
use File::Find::Rule;

# Figure out what module we are in.  A module is in a directory:
#    My-Mod-Name-1.00
# It includes any number of .pm files, each of which contain a single
# package.  Every package is named:
#    My::Pack::Name
# and includes a variable:
#    My::Pack::Name::VERSION

my $testdir = $ti->testdir();
my $moddir  = $ti->testdir('mod');
my $libdir  = $ti->testdir('lib');
my @dir     = split(/\//,$moddir);
my $dir     = pop(@dir);

my($mod,$vers,$valid);
if ($dir =~ /^(.*)\-(\d+\.\d+)$/) {
   $mod     = $1;
   $vers    = $2;
   $valid   = 1;
} else { 
   $valid   = 0;
}

# If there is a file _version.ign, it should be a list of filename
# substrings to ignore (any .pm file with any of these substrings
# will be ignored).

my @ign     = ();
if (-f "$testdir/_version.ign") {
   open(IN,"$testdir/_version.ign");
   @ign     = <IN>;
   close(IN);
   chomp(@ign);
}

$ti->ok($valid,"Valid directory");
$ti->skip_all('Remaining tests require a valid directory')  if (! defined $vers);

my $in      = new IO::File;
my @files   = File::Find::Rule->file()->name('*.pm')->in($libdir);

FILE:
foreach my $file (@files) {

   foreach my $ign (@ign) {
      next FILE  if ($file =~ /\Q$ign\E/);
   }

   $in->open($file);
   my @tmp = <$in>;
   chomp(@tmp);
   my @v   = grep /^\$VERSION\s*=\s*['"]\d+\.\d+['"];$/, @tmp;
   if (! @v) {
      $ti->ok(0,$file);
      $ti->diag('File contains no valid version line');
   } elsif (@v > 1) {
      $ti->ok(0,$file);
      $ti->diag('File contains multiple version lines');
   } else {
      $v[0] =~ /['"](\d+\.\d+)['"]/;
      my $v = $1;
      $ti->is($v,$vers,$file);
      $ti->diag('File contains incorrect version number')  if ($v ne $vers);
   }
}

$ti->done_testing();

