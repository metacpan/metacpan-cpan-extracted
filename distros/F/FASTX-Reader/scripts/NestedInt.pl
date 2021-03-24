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

print STDERR "Usage: $0 FILE1 FILE2\n";
print STDERR 'version: ', $FASTX::Reader::VERSION, "\n\n";
# Read two samples files if the user didnt provide any filename

my  $seq_reader1 = FASTX::Reader->new({filename => "$ARGV[0]"});
my  $seq_reader2 = FASTX::Reader->new({filename => "$ARGV[1]"});

say $ARGV[0], "\t|\t", $ARGV[1];
while (my $s1 = $seq_reader1->getRead() and my $s2 = $seq_reader2->getRead()) {
        
    print $s1->{name}, "\t|\t", $s2->{name}, "\n";

} 