use 5.012;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use File::Spec::Functions;
use FASTX::Reader;
use FASTX::ReaderPaired;
use FASTX::Seq;
use Data::Dumper;
# TEST: Parse a regular file as interleaved (error)



my @files = qw(alpha.fa illumina_1.fq.gz file2.fa compressed.fasta.gz compressed.fastq.gz);
my $seq = undef;
my $badSeq = undef;
eval {
  $seq = FASTX::Seq->new(
    -seq =>     "AAAAACAGATANNNN",
    -quality => "II:IIIIA981!!!!",
    -offset  => 33,
    -line_len => 80);
};

isa_ok($seq, 'FASTX::Seq');
ok($@ eq '', "No errors raised: " . $@);
eval {
    my $badSeq = FASTX::Seq->new(
    -seq =>     "AAAAACAGATANNNN",
    -quality => "II:IIIIA981!!!!",
    -offset  => 33,
    -badattr => 80);
};
ok($@ ne '', "Unknown flag raises errors: " . $@);

done_testing();
