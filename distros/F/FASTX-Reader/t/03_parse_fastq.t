use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;

use FASTX::Reader;
my $seq_file = "$RealBin/../data/test.fastq";

# TEST: Retrieves seq_fileuences from a test FASTQ file

# Check required input file
if (! -e $seq_file) {
  print STDERR "Skip test: $seq_file not found\n";
  exit 0;
}

my $data = FASTX::Reader->new({ filename => "$seq_file" });

# Retrieve first sequence
my $seq = $data->getRead();

# Check seq for unexpected chars (legally all IUPAC chars are allowed, but in the given example they are not expected)
my $copy = $seq->{seq};
my $len = length($copy);
ok( $len > 0 , "[FASTQ] Received a string as sequence, $len bp long");
$copy =~s/[ACGTNacgtn]//g;
ok(length($copy) == 0, '[FASTQ] Sequence does not contain unexcpected chars');
ok(length($seq->{seq}) == length($seq->{qual}), '[FASTQ] Sequence and quality length are the same');

done_testing();
