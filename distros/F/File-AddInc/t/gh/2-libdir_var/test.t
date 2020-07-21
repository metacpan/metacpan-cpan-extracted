#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;

use Test::More;
use File::Basename;

my $testName = $FindBin::Bin;
my $distDir = dirname(dirname(dirname($FindBin::Bin)));

# print "distDir=$distDir\ntestName=$testName\n";

subtest q{use File::AddInc qw($libdir)}, sub {
  my $testDir = File::Spec->rel2abs($testName);
  my $targetFile = "MyApp.pm";

  is qx($^X -I$distDir/lib $testDir/$targetFile), "FOObar\n", "\$libvar is set";
};

subtest q{use File::AddInc [libdir_var => qw($libdir)]}, sub {
  my $testDir = File::Spec->rel2abs($testName);
  my $targetFile = "MyApp2.pm";

  is qx($^X -I$distDir/lib $testDir/$targetFile), "FOObar\n", "\$libvar is set";
};

subtest q{use File::AddInc [these_libdirs => 'etc', q{}, 'perl5']}, sub {
  my $testDir = File::Spec->rel2abs($testName);
  my $targetFile = "MyApp3.pm";

  is qx($^X -I$distDir/lib $testDir/$targetFile), "FOObar\n", "these_libdirs works";
};

subtest q{use MyExporter 'etc', q{}, 'perl5'}, sub {
  my $testDir = File::Spec->rel2abs($testName);
  my $targetFile = "MyApp4.pm";

  is qx($^X -I$distDir/lib -I$testDir/other_lib $testDir/$targetFile), "FOObar\n", "MyExporter works";
};


done_testing();
