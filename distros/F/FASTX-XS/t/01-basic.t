#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FASTX::XS;

# Create a test FASTA file
my $fasta_file = "test.fa";
open my $fh, '>', $fasta_file or die "Could not create test file: $!";
print $fh <<'FASTA';
>seq1 This is sequence 1
ACGTACGTACGT
>seq2 This is sequence 2
GTCAGTCAGTCA
FASTA
close $fh;

# Test FASTA parsing
my $parser = FASTX::XS->new($fasta_file);
ok($parser, "Created parser object for FASTA file");

my $seq1 = $parser->next_seq();
ok($seq1, "Got first sequence");
is($seq1->{name}, "seq1", "Correct sequence name");
is($seq1->{seq}, "ACGTACGTACGT", "Correct sequence");
is($seq1->{comment}, "This is sequence 1", "Correct comment");
ok(!exists $seq1->{qual}, "No quality for FASTA");

my $seq2 = $parser->next_seq();
ok($seq2, "Got second sequence");
is($seq2->{name}, "seq2", "Correct sequence name");
is($seq2->{seq}, "GTCAGTCAGTCA", "Correct sequence");
is($seq2->{comment}, "This is sequence 2", "Correct comment");

my $seq3 = $parser->next_seq();
ok(!defined $seq3, "No more sequences");

# Clean up test file
unlink $fasta_file;

done_testing();