#!/usr/bin/env perl
use 5.012;
use autodie;
use Carp qw(confess);
use FindBin qw($Bin);
use lib "$Bin/../lib/";
use FASTX::Reader;

# Read two samples files if the user didnt provide any filename
unless ($ARGV[0]) {
 say STDERR "[WARNING] No input file specified, using test data";
 push(@ARGV,"$Bin/../data/test.fastq", "$Bin/../data/test.fasta" )
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

=head1 NAME

B<Counter.pl> - Demo script using FASTX::Reader to count sequences in FASTA / FASTQ files

=head1 USAGE

  Counter.pl FILE1 FILE2 ... FILE{n}

If no arguments are supplied, it will parse two test files contained in the script directory

=head1 WEBSITES

=over 4

=item L<https://github.com/telatin/FASTQ-Parser>


The B<GitHub> repository for this module

=item L<https://metacpan.org/pod/FASTX::Reader>

The B<MetaCPAN> page for this module

=back

=cut
