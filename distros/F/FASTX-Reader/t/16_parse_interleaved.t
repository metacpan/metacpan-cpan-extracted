use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use FASTX::Reader;
use FASTX::PE;

# TEST: Parse an interleaved file

my $seq_file = "$RealBin/../data/interleaved.fq.gz";

# Check required input file
if (! -e $seq_file) {
  print STDERR "Skip test: $seq_file not found\n";
  exit 0;
}

my $data = FASTX::PE->new({ filename => "$seq_file", interleaved => 1, verbose => 1 });
my $pe = $data->getReads();
 
ok(defined $pe->{seq1},  "[PE] sequence1 is defined");
ok(defined $pe->{seq2},  "[PE] sequence2 is defined");
ok(defined $pe->{qual1}, "[PE] quality1 is defined");
ok(defined $pe->{qual2}, "[PE] quality2 is defined");

done_testing();
