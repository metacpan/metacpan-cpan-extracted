#!/usr/bin/env perl
use 5.010;
use Carp qw(confess);
use FindBin qw($RealBin);
use lib "$RealBin/../lib/";
use FASTX::Reader;

push(@ARGV,"$RealBin/../data/test.fastq", "$RealBin/../data/dataset.fastq.gz" );

foreach my $file (@ARGV) {
  my $R = FASTX::Reader->new({ filename => "$file"});
  while (my $seq = $R->getRead() ) {
    $l += length($s->{seq});
  }
}
say "$l";
