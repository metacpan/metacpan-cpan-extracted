# FASTX-Parser

OOP Perl module to parse FASTA/FASTQ files, without depending on BioPerl

## Origin

Based on Heng Li's FAST* parser subroutine (https://github.com/lh3/readfq) and its minor updates
reported here (https://github.com/telatin/readfq/blob/master/readfq.pl)

## Usage

```perl

use FASTX::Reader;
my $seq_reader = FASTX::Reader->new({filename => "$input_file"});
while (my $seq = $seq_reader->getRead()) {

      # Print FASTA or FASTQ accordingly (check 'qual' defined)
      if (defined $seq->{qual}) {
        print '@', $seq->{name}, ' ', $seq->{comment}, "\n", $seq->{seq}, "\n+\n", $seq->{qual}, "\n";
      } else {
        print ">", $seq->{name}, ' ', $seq->{comment}, "\n", $seq->{seq}, "\n";
      }
    }

```
