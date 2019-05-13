#!/usr/bin/env perl
use 5.012;
use autodie;
use Term::ANSIColor;
use Data::Dumper;
use Carp qw(confess);
use FindBin qw($Bin);
use lib "$Bin/../lib/";
use FASTX::Reader;
say STDERR color('bold'), "TEST FASTA/FASTQ READER", color('reset');
say STDERR color('bold'), "Read FASTA/FASTQ files, printing them back to the user", color('reset');
say STDERR "Usage: $0 FILE1 FILE2 ... FILEn\n";

# Read two samples files if the user didnt provide any filename
push(@ARGV,"$Bin/test.fastq", "$Bin/test.fasta" )
  unless ($ARGV[0]);

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
    while (my $seq = $seq_reader->getRead()) {
      $counter++;
      # Print FASTA or FASTQ accordingly (check 'qual' defined)
      if (defined $seq->{qual}) {
        print '@', $seq->{name}, ' ', $seq->{comment}, "\n", $seq->{seq}, "\n+\n", $seq->{qual}, "\n";
      } else {
        print ">", $seq->{name}, ' ', $seq->{comment}, "\n", $seq->{seq}, "\n";
      }
    }
    say STDERR color('green'), "] Finished $input_file: $counter sequences", color('reset') if ($counter);
  }
}

=head1 NAME

B<reader.pl> - A minimal implementation of the FASTX::Reader module to show how to parse a FASTA/FASTQ files

=head1 USAGE

  reader.pl FILE1 FILE2 ... FILE{n}

If no arguments are supplied, it will parse two test files contained in the script directory

=head1 NOTES

The printed sequences can be slightly different from the input file as the header will be C<{name}{space}{comments}>, but any white space (including a tab) could be the
comment separator

=head1 WEBSITES

=over 4

=item L<https://github.com/telatin/FASTQ-Parser>


The B<GitHub> repository for this module

=item L<https://metacpan.org/pod/FASTX::Reader>

The B<MetaCPAN> page for this module

=back

=head1 AUTHORS

=over 4

=item Andrea Telatin

=item Fabrizio Levorin

=back

=cut
