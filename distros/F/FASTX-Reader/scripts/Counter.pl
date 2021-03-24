#!/usr/bin/env perl
use 5.010;
use Carp qw(confess);
use FindBin qw($RealBin);
use lib "$RealBin/../lib/";
use FASTX::Reader;

# Read two samples files if the user didnt provide any filename
unless ($ARGV[0]) {
 say STDERR "[WARNING] No input file specified, using test data";
 push(@ARGV,"$RealBin/../data/test.fastq", "$RealBin/../data/test.fasta" );
 say STDERR<<END;
 Counter.pl - Script using FASTX::Reader to count sequences in FASTA/FASTQ files
 -------------------------------------------------------------------------------
 USAGE

   Counter.pl FILE1 FILE2 ... FILE{n}

 If no arguments are supplied, it will parse two test files contained in the script directory
 -------------------------------------------------------------------------------
END
}

foreach my $input_file (@ARGV) {
  # Skip non existing files
  if ( not -e "$input_file") {
    next;
  } else {
    my  $seq_reader = FASTX::Reader->new({filename => "$input_file"});
    my $counter = 0;
    while (my $seq = $seq_reader->getRead()) {
      $counter++;
    }
    if ($counter) {
	say $input_file, "\t", $counter;
    } else {
	say STDERR "$input_file\t[Probably not in FASTA/FASTQ format]";
    }
  }
}
