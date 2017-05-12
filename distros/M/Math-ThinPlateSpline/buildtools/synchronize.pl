#!/usr/bin/env perl
use strict;
use warnings;
use File::Copy qw/cp/;
use File::Spec;
use File::Path qw/rmtree/;
my $Git = 'git';

system($Git, 'clone', 'git://github.com/tsee/tpsfit.git') and die $!;

my $target = File::Spec->updir();
my $source = File::Spec->catdir("tpsfit", "src");

my @files = qw(
  ThinPlateSpline.cc
  ThinPlateSpline.h
  linalg3d.cc
  linalg3d.h
  TPSException.h
  ludecomposition.h
);

foreach my $file (@files) {
  my $sfile = File::Spec->catfile($source, $file);
  cp($sfile, $target)
    or die "Copying $sfile to $target failed: $!";
}

rmtree("tpsfit");

