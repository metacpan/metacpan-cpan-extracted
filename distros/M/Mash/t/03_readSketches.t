#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use Data::Dumper;
use FindBin qw/$RealBin/;
use lib "$RealBin/../lib";

use Test::More tests=>3;
use Mash;
my %expected = (
  "PNUSAL003567_R2_.fastq.gz" => {
    "PNUSAL003567_R1_.fastq.gz" => 0.0134525,
  },
  "PNUSAL003567_R1_.fastq.gz" => {
    "PNUSAL003567_R2_.fastq.gz" => 0.0134525,
  },
);

# Distances between two mash sketches
my $sketch1 = Mash->new("$RealBin/data/PNUSAL003567_R1_.fastq.gz.msh");
my $sketch2 = Mash->new("$RealBin/data/PNUSAL003567_R2_.fastq.gz.msh");
my $distHash = $sketch1->distance($sketch2);
is_deeply($distHash, \%expected, "Mash distances for msh");

# Convert to JSON, removing whitespace the perl way
open(my $fh1, "mash info -d $RealBin/data/PNUSAL003567_R1_.fastq.gz.msh | ") or die "ERROR: could not run mash info -d on $RealBin/data/PNUSAL003567_R1_.fastq.gz.msh: $!";
open(my $out1, ">", "$RealBin/data/PNUSAL003567_R1_.fastq.gz.msh.json") or die "ERROR: could not write to $RealBin/data/PNUSAL003567_R1_.fastq.gz.msh.json: $!";
while(<$fh1>){
  s/\s+//g;
  print $out1 $_;
}
close $fh1;
close $out1;

open(my $fh2, "mash info -d $RealBin/data/PNUSAL003567_R2_.fastq.gz.msh | ") or die "ERROR: could not run mash info -d on $RealBin/data/PNUSAL003567_R2_.fastq.gz.msh: $!";
open(my $out2, ">", "$RealBin/data/PNUSAL003567_R2_.fastq.gz.msh.json") or die "ERROR: could not write to $RealBin/data/PNUSAL003567_R2_.fastq.gz.msh.json: $!";
while(<$fh2>){
  s/\s+//g;
  print $out2 $_;
}
close $fh2;
close $out2;

# Distances between JSON files
$sketch1 = Mash->new("$RealBin/data/PNUSAL003567_R1_.fastq.gz.msh.json");
$sketch2 = Mash->new("$RealBin/data/PNUSAL003567_R2_.fastq.gz.msh.json");
$distHash = $sketch1->distance($sketch2);
is_deeply($distHash, \%expected, "Mash distances for JSON");

# Distance between the JSON.gz equivalent
system("gzip -c9 $RealBin/data/PNUSAL003567_R1_.fastq.gz.msh.json > $RealBin/data/PNUSAL003567_R1_.fastq.gz.msh.json.gz");
system("gzip -c9 $RealBin/data/PNUSAL003567_R2_.fastq.gz.msh.json > $RealBin/data/PNUSAL003567_R2_.fastq.gz.msh.json.gz");
$sketch1 = Mash->new("$RealBin/data/PNUSAL003567_R1_.fastq.gz.msh.json.gz");
$sketch2 = Mash->new("$RealBin/data/PNUSAL003567_R2_.fastq.gz.msh.json.gz");
$distHash = $sketch1->distance($sketch2);
is_deeply($distHash, \%expected, "Mash distances for JSON.gz");

