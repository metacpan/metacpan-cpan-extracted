use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use FASTX::Reader;

# TEST: Retrieves sequences from a test FASTA file

my $seq_file = "$RealBin/../data/test.fasta";

# Check required input file
if (! -e $seq_file) {
  print STDERR "Skip test: $seq_file not found\n";
  exit 0;
}

my $data = FASTX::Reader->new({ filename => "$seq_file" });
my $seq = $data->getRead();

ok(defined $seq->{seq}, "[FASTA] sequence is defined");

my $copy = $seq->{seq};
my $len = length($copy);

# Check that the sequence has a length (i.e. non null string)
ok($len > 0 , "[FASTA] Received a string as sequence, $len bp long");
$copy =~s/[ACGTNacgtn]//g;

# Check that sequence only containse expected chars
ok(length($copy) == 0, '[FASTA] Sequence does not contain unexcpected chars');


done_testing();
