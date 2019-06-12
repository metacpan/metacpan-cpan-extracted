#!/usr/bin/env perl
use 5.012;
use autodie;
use Term::ANSIColor;
use Data::Dumper;
use Carp qw(confess);
use FindBin qw($Bin);
use lib "$Bin/../lib/";
use FASTX::Reader;
my $seq_reader;
$seq_reader = FASTX::Reader->new();
my $counter = 0;

say STDERR<<END;
  A script to check reading from STDIN.

  USAGE:
  cat file.fasta | $0

END

while (my $seq = $seq_reader->getRead()) {
      $counter++;
      # Print FASTA or FASTQ accordingly (check 'qual' defined)
      if (defined $seq->{qual}) {
        print '@', $seq->{name}, ' ', $seq->{comment}, "\n", $seq->{seq}, "\n+\n", $seq->{qual}, "\n";
      } else {
        print ">", $seq->{name}, ' ', $seq->{comment}, "\n", $seq->{seq}, "\n";
      }
}
my $color = 'cyan';
$color = 'red' if ($seq_reader->{status});
say STDERR color('green'), "] Finished: $counter sequences\n", color($color),
  'Message: ', $seq_reader->{message},
  'Status: ',  $seq_reader->{status}, color('reset') if ($counter);
