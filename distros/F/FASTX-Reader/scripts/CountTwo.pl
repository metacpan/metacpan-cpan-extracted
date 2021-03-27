#!/usr/bin/env perl
use 5.010;
use Term::ANSIColor;
use Data::Dumper;
use Carp qw(confess);
use FindBin qw($RealBin);
use lib "$RealBin/../lib/";
use FASTX::Reader;
use File::Basename;
# Print splash screen
print STDERR color('bold'), "TEST FASTA/FASTQ READER\n", color('reset');
print STDERR color('bold'), "Read FASTA/FASTQ files, printing them back to the user\n", color('reset');
print STDERR "Usage: $0 FILE1 FILE2\n";
print STDERR 'version: ', $FASTX::Reader::VERSION, "\n\n";
# Read two samples files if the user didnt provide any filename

my $file1 = $ARGV[0] // "$RealBin/../data/alpha.fa";
my $file2 = $ARGV[0] // "$RealBin/../data/beta.fa";
my %counters = ();

my $R1 = FASTX::Reader->new({ filename => $file1});
while ($R1->getRead() ) { $counters{'File1_alone'}++; }
my $R2 = FASTX::Reader->new({ filename => $file2});
while ($R2->getRead() ) { $counters{'File2_alone'}++; }
say $file1,' ', $counters{'File1_alone'};
say $file2,' ', $counters{'File2_alone'};
