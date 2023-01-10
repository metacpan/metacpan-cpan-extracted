#!/usr/bin/env perl
use 5.012;
use warnings;
use Pod::Usage;
use Term::ANSIColor;
use Getopt::Long;
use FindBin qw($RealBin);
use File::Basename;

use Data::Dumper;
use JSON::PP;
# The following placeholder is to be programmatically replaced with 'use lib "$RealBin/../lib"' if needed
#~loclib~
if ( -e "$RealBin/../lib/Proch/N50.pm" and -e "$RealBin/../Changes" ) {
    use lib "$RealBin/../lib";
}
use FASTX::Reader;


my $data1 = FASTX::Reader->new({ filename => $ARGV[0] });
my $data2 = FASTX::Reader->new({ filename => $ARGV[0] });

my $count1 = 0;
my $count2 = 0;
my $tot1 = 0;
my $tot2 = 0;

while (my $seq = $data1->getRead() ) {
    $count1++;
    $tot1 += length($seq->{seq});
}

while (my $seq = $data2->next() ) {
    $count2++;
    $tot2 += length($seq->seq);
}
say "Num reads:\t$count1\t$count2";
say "Total len:\t$tot1\t$tot2";