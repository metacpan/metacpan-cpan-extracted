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

my $seq = FASTX::Seq->new(
  -seq =>     "AAAAACAGATANNNN",
  -quality => "II:IIIIA981!!!!",
  -offset  => 32,
  -line_len => 80);

ok($seq->is_fasta() == 0, "FASTA record not detected = ". $seq->is_fasta());
ok($seq->is_fastq() == 1, "FASTQ record detected = ". $seq->is_fastq());
ok($seq->len() == 15, "Sequence length = ". $seq->len());
ok($seq->seq eq 'AAAAACAGATANNNN', "Sequence = ". $seq->seq());
ok($seq->{seq} eq 'AAAAACAGATANNNN', "Sequence = ". $seq->{seq});
ok($seq->offset() == 32, "Quality offset = ". $seq->offset());

my $copy = $seq->copy();
ok($copy->is_fasta() == 0, "FASTA record not detected = ". $copy->is_fasta());
ok($copy->seq eq 'AAAAACAGATANNNN', "Sequence = ". $copy->seq());
ok($copy->{seq} eq 'AAAAACAGATANNNN', "Sequence = ". $copy->{seq});
ok($copy->qual eq 'II:IIIIA981!!!!', "Quality = ". $copy->qual());
ok($copy->{qual} eq 'II:IIIIA981!!!!', "Quality = ". $copy->{qual});
ok($copy->len() == 15, "Sequence length = ". $copy->len());
ok($copy->offset() == 32, "Quality offset = ". $copy->offset());

say Dumper $copy;
done_testing();
