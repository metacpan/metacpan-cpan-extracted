#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;

use Test::More;
use File::Basename;

if (do {eval {require MOP4Import::Declare}; $@}) {
  plan skip_all => "MOP4Import::Declare is not installed";
}

my $testName = $FindBin::Bin;
my $distDir = dirname(dirname($FindBin::Bin));

# print "distDir=$distDir\ntestName=$testName\n";

subtest q{use MOP4Import::Declare -as_base, [parent => 'File::AddInc']}, sub {
  my $testDir = File::Spec->rel2abs($testName);
  my $targetFile = "lib_b/Foo.pm";

  is qx($^X -I$distDir/lib -I$testDir/lib_a $testDir/$targetFile), "OK\n", "-file_inc is available in MyExporter2";
};

done_testing();
