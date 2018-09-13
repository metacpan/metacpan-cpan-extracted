#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::Most;
use Test::Compile;

use File::Find;


ok(1, "Scenario: Find all .pl and .pm -files and check if they actually compile");

#Find files in the usual places
my $searchDir = "$FindBin::Bin/../lib/";
File::Find::find( \&testLib, $searchDir );

testBin("$FindBin::Bin/../bin/hetula-client");


sub testLib {
  my ($filename) = @_;
  $filename = $File::Find::name unless $filename;

  return unless $filename =~ m/\.p[ml]$/;

  require_ok($filename);
}

sub testBin {
  my ($filename) = @_;
  my $testCompile = Test::Compile->new();
  ok($testCompile->pl_file_compiles($filename), "$filename");
}

done_testing();
