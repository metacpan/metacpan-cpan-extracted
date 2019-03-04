#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use Data::Dumper;
use FindBin qw/$RealBin/;
use lib "$RealBin/../lib";

use Test::More tests=>1;
use Mash;

my $sketch1 = Mash->new("$RealBin/data/PNUSAL003567_R1_.fastq.gz.msh");
my $sketch2 = Mash->new("$RealBin/data/PNUSAL003567_R2_.fastq.gz.msh");

my %expected = (
  "PNUSAL003567_R2_.fastq.gz" => {
    "PNUSAL003567_R1_.fastq.gz" => 0.0134525,
  },
  "PNUSAL003567_R1_.fastq.gz" => {
    "PNUSAL003567_R2_.fastq.gz" => 0.0134525,
  },
);

my $distHash = $sketch1->distance($sketch2);
is_deeply($distHash, \%expected, "Mash distances");

