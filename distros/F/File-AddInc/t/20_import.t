#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use rlib "../lib";

#========================================

use Test::Kantan;
use File::Basename;
use File::Spec;

#----------------------------------------

sub lines (@) { map {"$_\n"} @_ }

describe "use File::AddInc", sub {

  (my $testName = $0) =~ s/\.t\z//;

  {
    my $testDesc = "$testName/1.d";
    my $testDir = File::Spec->rel2abs($testDesc);
    my $targetFile = "MyApp/Deep/Runnable/Module.pm";

    describe "case $testDesc/$targetFile", sub {

      my $exe = File::Spec->catfile($testDir, $targetFile);

      it "should emit correct libdir and can use other lib (MyApp::Util)", sub {

        expect([qx($^X -I$FindBin::Bin/../lib $exe)])
          ->to_be([lines($testDir, qw/OK BAR/)]);
      };
    };
  }

  {
    my $testDesc = "$testName/2.d";
    my $testDir = File::Spec->rel2abs($testDesc);
    my $targetFile = "scripts/mybar";

    describe "case $testDesc/$targetFile", sub {

      my $exe = File::Spec->catfile($testDir, $targetFile);

      return unless -l $exe; # Only test for symbolic link.

      it "should resolve symlink, emit correct libdir even for obscure-dir and can use other lib", sub {

        expect([qx($^X -I$FindBin::Bin/../lib $exe)])
          ->to_be([lines("$testDir/obscure-lib-dir", qw/OK YES!/)]);
      };
    };
  }

  {
    my $testDesc = "$testName/3.d";
    my $testDir = File::Spec->rel2abs($testDesc);
    my $targetFile = "lib/Foo.pm";

    describe "case $testDesc/$targetFile", sub {

      my $exe = File::Spec->catfile($testDir, $targetFile);

      it "should use local/lib/perl5 too", sub {

        expect([qx($^X -I$FindBin::Bin/../lib $exe)])
          ->to_be(["OK\n"]);
      };
    };
  }
};

done_testing();

sub read_file_lines {
  my ($fn) = @_;
  open my $fh, '<', $fn or Carp::croak "Can't open $fn: $!";
  chomp(my @lines = <$fh>);
  wantarray ? @lines : \@lines;
}
