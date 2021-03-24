#!/usr/bin/env perl
use 5.010;
use Term::ANSIColor;
use Data::Dumper;
use Carp qw(confess);
use FindBin qw($RealBin);
use lib "$RealBin/../lib/";
use FASTX::Reader;
say STDERR color('bold'), "TEST FASTA/FASTQ READER", color('reset');
say STDERR color('bold'), "Read FASTA/FASTQ files, printing them back to the user", color('reset');
say STDERR "Usage: $0 FILE1 FILE2 ... FILEn\n";

# Read two samples files if the user didnt provide any filename

unless ($ARGV[0]) {
      say STDERR<<END;
  FastqReader.pl - A minimal implementation of the FASTX::Reader module to show
  how to parse a FASTQ files with the faster getFastqRead() method.

  USAGE

      FastqReader.pl FILE1 FILE2 ... FILE{n}

  If no arguments are supplied, it will parse two test files contained in the
  script directory

  NOTE
  The printed sequences can be slightly different from the input file as the
  header will be {name}{space}{comments}, but any white space (including a tab)
  could be the comment separator

END
push(@ARGV,"$RealBin/../data/test.fastq", "$RealBin/../data/test.fasta" )
}

foreach my $input_file (@ARGV) {
  # Skip non existing files
  if ( not -e "$input_file" and "$input_file" ne 'STDIN') {
    say STDERR color('red'), "] Skipping: $input_file (not exists)", color('reset');
    next;
  } else {
    my $seq_reader;
    if ($input_file eq 'STDIN') {
      say STDERR color('bold'), 'Reading STDIN', color('reset');
      $seq_reader = FASTX::Reader->new();
    } else {
      $seq_reader = FASTX::Reader->new({filename => "$input_file"});
    }
    # Parse the existing files (no check on file type?)
    say STDERR color('yellow'), "] Reading: $input_file", color('reset');

    my $counter = 0;
    while (my $seq = $seq_reader->getFastqRead()) {
      $counter++;
      # Print FASTA or FASTQ accordingly (check 'qual' defined)
      print '@', $seq->{name}, ' ', $seq->{comment}, "\n", $seq->{seq}, "\n+\n", $seq->{qual}, "\n";
    }
    my $color = 'red bold';
    $color = 'cyan' if ($seq_reader->{status});
    say STDERR color('green'), "] Finished $input_file: $counter sequences\n", color($color),
      'Message: ', $seq_reader->{message},
      ' Status: ', $seq_reader->{status}, "\n", color('reset');
  }
}
