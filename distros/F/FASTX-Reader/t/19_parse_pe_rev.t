use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use FASTX::Reader;
use FASTX::PE;

# TEST: Manually compare the reverse complement of R2 with the one produced by FASTX::PE

my $seqfile1 = "$RealBin/../data/illumina_1.fq.gz";
my $seqfile2 = "$RealBin/../data/illumina_2.fq.gz";
# Check required input file
if (! -e $seqfile1) {
  print STDERR "Skip test: $seqfile1 (R1) not found\n";
  exit 0;
}
if (! -e $seqfile2) {
  print STDERR "Skip test: $seqfile2 (R2) not found\n";
  exit 0;
}
my $R2   = FASTX::Reader->new({
    filename => "$seqfile2",
});
my $revseq = $R2->getRead();

my $data = FASTX::PE->new({ 
    filename => "$seqfile1",
    rev      => "$seqfile2",
    revcompl => 1,
});
 
my $pe = $data->getReads();

my $rc = reverse($revseq->{seq});
$rc =~tr/ACGTacgt/TGCAtgca/;
ok($pe->{seq2} eq $rc, "[REVCOMPL] R2 sequence has been changed to reverse complementary");



done_testing();
