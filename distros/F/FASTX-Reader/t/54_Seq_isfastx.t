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

for my $f (@files) {
  my $seq_file = catfile($RealBin, "..", "data", $f);
  my $format = ($f =~ /\.(fq|fastq)/) ? 'fastq' : 'fasta';

  # Check required input file
  if (! -e $seq_file) {
    print STDERR "Skip test: $seq_file not found\n";
    done_testing();
    exit 0;
  }
  my $data = FASTX::Reader->new({
      filename => "$seq_file"
  });


  my $seq = $data->next();
  my $is_fasta = $seq->is_fasta();
  my $is_fastq = $seq->is_fastq();
  # Valid object
  if ($format eq 'fasta') {
    ok($is_fasta == 1, "[is:$f] $format record is FASTA");
    ok($is_fastq == 0, "[is:$f] $format record is not FASTQ");
  } elsif ($format eq 'fastq') {
    ok($is_fasta == 0, "[is:$f] $format record is not FASTA");
    ok($is_fastq == 1, "[is:$f] $format record is FASTQ");
  }
}

done_testing();
