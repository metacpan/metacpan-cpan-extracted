use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;

use FASTX::Reader;
my $seq = "$RealBin/../data/compressed.fasta.gz";

# Check required input file
if (! -e $seq) {
  print STDERR "Skip test: $seq not found\n";
  exit 0;
}

my $data = FASTX::Reader->new({ filename => "$seq" });

# Retrieve first sequence
$seq = $data->getRead();

# Check seq for unexpected chars (legally all IUPAC chars are allowed, but in the given example they are not expected)
my $copy = $seq->{seq};
my $len = length($copy);
ok( $len > 0 , "[FASTA.GZ] Received a string as sequence, $len bp long");
$copy =~s/[ACGTNacgtn]//g;
ok(length($copy) == 0, '[FASTA.GZ] Sequence does not contain unexcpected chars');

done_testing();
