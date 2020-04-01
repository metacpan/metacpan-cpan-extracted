#!/usr/bin/env perl
use 5.010;
use Carp qw(confess);
use FindBin qw($RealBin);
use lib "$RealBin/../lib/";
use FASTX::Reader;
use Benchmark qw{ timethese };
# Read two samples files if the user didnt provide any filename
unless ($ARGV[0]) {
 say STDERR "[WARNING] No input file specified, using test data";
 push(@ARGV,"$RealBin/../data/test.fastq", "$RealBin/../data/test.fasta" );
 say STDERR<<END;
 Counter.pl - Script using FASTX::Reader to count sequences in FASTA/FASTQ files
 -------------------------------------------------------------------------------
 USAGE

   Benchmark.pl FILE1 FILE2 ... FILE{n}

 If no arguments are supplied, it will parse two test files contained in the script directory
 -------------------------------------------------------------------------------
END
}

die "$ARGV[0] not found.\n" unless (-e $ARGV[0]);
my $load = '
my $c = 0;
my $l = 0;
my $R = FASTX::Reader->new({ filename => "' . $ARGV[0] . '" });
';

my $fx = $load . q(
  while (my $seq = $R->getRead()) {
    $c++;
    $l += length($seq->{seq});
  }
  print " $c\r";
);

my $fq = $load . q(
  while (my $seq = $R->getFastqRead()) {
    $c++;
    $l += length($seq->{seq});
  }
  print " $c\r";
);

say $fx;
say $fq;
timethese( 10000, {
        FxReader    => $fx,
        FqReader    => $fq,
  });
