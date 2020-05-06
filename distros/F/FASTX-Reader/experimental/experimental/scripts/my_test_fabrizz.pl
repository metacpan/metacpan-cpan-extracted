#!/usr/bin/perl
use 5.012;
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use FASTQ::Parser;


my $file = "$Bin/test.fasta";
my $fasta_parser = FASTQ::Parser->new({file => $file});

my $hr_seq = $fasta_parser->get_sequences;

foreach my $seq ( keys %$hr_seq ) {
	say '----------------------';
	say "NOME: $seq";
	say "SEQ: " . $$hr_seq{$seq}->{seq};
	say "QUAL: " . $$hr_seq{$seq}->{qual} if ($fasta_parser->{file_type} eq 'FASTQ');
}
