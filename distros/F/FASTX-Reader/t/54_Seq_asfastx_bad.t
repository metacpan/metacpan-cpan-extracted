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

  
  
  # Try with invalid quality:
  my $crooked = $seq->asfastq('WRONG');
  my @crooked_lines = split /\n/, $crooked;
  ok(length($crooked_lines[1]) == length($crooked_lines[3]), "[render:$f] as FASTQ (custom qual, invalid): length of sequence and quality match");
  ok(substr($crooked_lines[3], 0, 1) ne substr('WRONG', 0, 1), "[render:$f] as FASTQ (custom qual, invalid): quality does not start with W");

}

done_testing();
