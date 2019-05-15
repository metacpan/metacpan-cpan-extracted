#!/usr/bin/env perl

use 5.018;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use FASTX::Abi;
use Data::Dumper;
my $test_het = "$Bin/../data/hetero.ab1";
my $test_omo = "$Bin/../data/mt.ab1";

#$test = $ARGV[0] if (defined $ARGV[0] and -e "$ARGV[0]");



my $fastq_h = FASTX::Abi->new({
  filename  => "$test_het",
  trim_ends => 1,
});

my $fastq_o = FASTX::Abi->new({
  filename  => "$test_omo",
  trim_ends => 1,
});

for my $o ($fastq_h, $fastq_o) {
  say "Name   :\t",   $o->{filename};
  say "Iso_seq:\t",$o->{iso_seq};
  say "Diffs  :\t",  $o->{diff};
  say $o->get_fastq();
}
