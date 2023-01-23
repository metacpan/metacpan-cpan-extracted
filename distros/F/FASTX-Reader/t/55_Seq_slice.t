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

my $seq = FASTX::Seq->new("AAAAACAGATANNNN");
my $copy = $seq;
# Discard the first bases
my $slice = $seq->slice(5);
isa_ok($seq, 'FASTX::Seq');
isa_ok($slice, 'FASTX::Seq');
ok($slice->seq eq "CAGATANNNN", "Slice(5) sequence is correct: " . $slice->seq);

# From / len
my $slice_len = $seq->slice(5, 6);
isa_ok($slice_len, 'FASTX::Seq');
ok($slice_len->seq eq "CAGATA", "Slice(5,6) sequence is correct: " . $slice_len->seq);

# Negative value
my $slice_lend = $seq->slice(5, -4);
isa_ok($slice_lend, 'FASTX::Seq');
ok($slice_lend->seq eq "CAGATA", "Slice(5,-4) sequence is correct: " . $slice_lend->seq);

# 0 5
my $slice_0 = $seq->slice(0, 5);
isa_ok($slice_0, 'FASTX::Seq');
ok($slice_0->seq eq "AAAAA", "Slice(0,5) sequence is correct: " . $slice_0->seq);

# Is the original sequence unchanged?
ok($seq->seq() eq "AAAAACAGATANNNN", "Original sequence is unchanged: " . $seq->seq);
$seq->slice(5);
ok($copy->seq() eq "AAAAACAGATANNNN", "Copy sequence is unchanged: " . $copy->seq);
done_testing();
