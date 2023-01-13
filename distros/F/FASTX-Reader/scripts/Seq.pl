#!/usr/bin/env perl
use 5.010;
use Term::ANSIColor;
use Data::Dumper;
use Carp qw(confess);
use FindBin qw($RealBin);
use lib "$RealBin/../lib/";
use FASTX::Reader;

my $Reader = FASTX::Reader->new({ filename => "$ARGV[0]"});

while (my $seq = $Reader->next() ) {
    say "AS FASTQ Name=", $seq->name, " Length=", $seq->len;
    print $seq->as_fastq();
    say "-- Overwrite with: A -----------------";
    print $seq->as_fastq("A");
    say "-- Overwrite with: BAD -----------------";
    print $seq->as_fastq("BAD");    
}