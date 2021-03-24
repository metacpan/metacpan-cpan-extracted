#!/usr/bin/env perl
use 5.010;
use Term::ANSIColor;
use Data::Dumper;
use Carp qw(confess);
use FindBin qw($RealBin);
use lib "$RealBin/../lib/";
use FASTX::Reader;
use File::Basename;

say $FASTX::Reader::VERSION;
# Print splash screen
print STDERR color('bold'), "TEST FASTA/FASTQ READER\n", color('reset');
print STDERR color('bold'), "Read FASTA/FASTQ files, printing them back to the user\n", color('reset');
print STDERR "Usage: $0 FILE1 FILE2\n";
print STDERR 'version: ', $FASTX::Reader::VERSION, "\n\n";
# Read two samples files if the user didnt provide any filename

if ($ARGV[0]){
      # Compare two seqs

      $seq_reader1 = FASTX::Reader->new({filename => "$ARGV[0]"});
      $seq_reader2 = FASTX::Reader->new({filename => "$ARGV[1]"});

      while (my $s1 = $seq_reader1->getRead() and my $s2 = $seq_reader2->getRead()) {
        my $color;
        ($s1->{name} !~/alpha/i or $s2->{name} !~/beta/i) ? $color = 'red' : $color = 'green';

        print color($color), basename($ARGV[0]), color('reset'), ':', $s1->{name}, color('red'), ' -> ',
              color($color), basename($ARGV[1]), color('reset'), ':', $s2->{name}, "\n";

      }

} else {
  for my $suffixes ('fa:fa', 'fq:fq', 'fa:fq', 'fq:fa') {

    my ($suffix_1, $suffix_2) = split /:/, $suffixes;
    $seq_reader1 = FASTX::Reader->new({filename => "$RealBin/../data/alpha.$suffix_1"});
    $seq_reader2 = FASTX::Reader->new({filename => "$RealBin/../data/beta.$suffix_2"});
    print color('bold'), "-- alpha.$suffix_1 -- beta.$suffix_2\n", color('reset');
    my $c = 0;
    while (1) {
      $c++;
      my $color;

      print "--- $c ---\n";
      my $s1 = $seq_reader1->getRead() || last;
      my $s2 = $seq_reader2->getRead() || last;
      ($s1->{name} !~/alpha/i or $s2->{name} !~/beta/i) ? $color = 'red' : $color = 'green';
      print color($color), 'alpha.', $suffix_1, color('reset'), ':', $s1->{name}, color('red'), ' -> ',
            color($color), 'beta.' , $suffix_2, color('reset'), ':', $s2->{name}, "\n";

    }

  }
}
