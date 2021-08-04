use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use FASTX::Reader;
use FASTX::PE;
BEGIN {

    eval {
        require File::Spec;
        Module->import( qw(devnull) );     # No need if you don't import any subroutines

        open STDERR, '>', File::Spec->devnull();
    };
}

# TEST: Test FASTX::PE working letting the module calculating the R2

my $seqfile1 = "$RealBin/../data/illumina_1.fq.gz";
my $expected = "$RealBin/../data/illumina_2.fq.gz";
# Check required input file
if (! -e $seqfile1) {
  print STDERR "Skip test: $seqfile1 (R1) not found\n";
  exit 0;
}
if (! -e $expected) {
  print STDERR "Skip test: $expected (R2) not found\n";
  exit 0;
}
my $data = FASTX::PE->new({
  filename => "$seqfile1",
  verbose => 1,
});
my $pe = $data->getReads();

ok(defined $pe->{seq1},  "[PE] sequence1 is defined");
ok(defined $pe->{seq2},  "[PE] sequence2 is defined");
ok(defined $pe->{qual1}, "[PE] quality1 is defined");
ok(defined $pe->{qual2}, "[PE] quality2 is defined");

done_testing();
