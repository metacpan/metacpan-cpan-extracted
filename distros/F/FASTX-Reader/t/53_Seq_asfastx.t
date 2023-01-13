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
  my $format = $f =~ /\.(fq|fastq)?$/ ? 'fastq' : 'fasta';

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

  # Valid object
  isa_ok($seq, 'FASTX::Seq');
  
  # FASTA
  my $as_fasta = $seq->asfasta();
  my $as_fasta_3 = $seq->asfasta(3);
  ok(substr($as_fasta, 0, 1) eq '>', "[render:$f] $format record rendered as FASTA");

  my $fasta_lines = () = $as_fasta =~ /\n/g;
  my $fasta_lines_3 = () = $as_fasta_3 =~ /\n/g;
  ok($fasta_lines == 2, "[render:$f] $format record rendered as FASTA (2 lines): " . $fasta_lines);
  my $max = int($seq->len() / 3);
  ok($fasta_lines_3 >= $max, "[render:$f] $format record rendered as FASTA(3) (>=$max lines): " . $fasta_lines_3);
  # FASTQ
  my $as_fastq = $seq->asfastq();
  my $as_fastq_A = $seq->asfastq('A');
  my $fastq_lines = () = $as_fastq =~ /\n/g;
  my $fastq_lines_A = () = $as_fastq_A =~ /\n/g;
  
  ok(substr($as_fastq, 0, 1) eq '@',   "[render:$f] $format record rendered as FASTQ: " . substr($as_fastq, 0, 1));
  ok(substr($as_fastq_A, 0, 1) eq '@', "[render:$f] $format record rendered as FASTQ (custom qual): " . substr($as_fastq_A, 0, 1));
  ok($fastq_lines == 4, "[render:$f] $format record rendered as FASTQ (4 lines): $fastq_lines");
  ok($fastq_lines_A == 4, "[render:$f] $format record rendered as FASTQ (custom qual, 4 lines): $fastq_lines_A");
  
  # Check aliases
  my $as_fastq_alias = $seq->as_fastq();
  my $as_fastq_alias_A = $seq->as_fastq('A');
  my $as_fasta_alias = $seq->as_fasta();
  ok($as_fastq eq $as_fastq_alias, "[render:$f] $format record rendered as FASTQ (alias)");
  ok($as_fasta eq $as_fasta_alias, "[render:$f] $format record rendered as FASTA (alias)");
  ok($as_fastq_A eq $as_fastq_alias_A, "[render:$f] $format record rendered as FASTQ (custom qual, alias)");
  my @parts = split /\n/, $as_fastq;
  ok(length($parts[1]) eq length($parts[3]), "[render:$f] as FASTQ: length of sequence and quality match");

}

done_testing();
