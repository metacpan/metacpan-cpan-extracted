#!/usr/bin/env perl
use 5.012;
use Term::ANSIColor;
use Data::Dumper;
use Carp qw(confess);
use FindBin qw($RealBin);
use lib "$RealBin/../lib/";
use FASTX::Reader;
use FASTX::Seq;
use Getopt::Long;

my $qual = "I";
my $offset = 33;
GetOptions(
    'q|qual=s' => \$qual,
    'o|offset=i' => \$offset,
);
say "Qual: $qual, ", unpack("C*", $qual);
$FASTX::Seq::DEFAULT_QUALITY = $qual if $qual;
$FASTX::Seq::DEFAULT_OFFSET = $offset if $offset;
my $int = unpack("C*", $qual) - $offset;

my $data = FASTX::Reader->new(
    -filename => "$ARGV[0]",
    -loadseqs => 'records');


for my $i ($data->records()->@*) {
    print $i->as_fasta() if $i->len() > 10;
}
say Dumper \$data;