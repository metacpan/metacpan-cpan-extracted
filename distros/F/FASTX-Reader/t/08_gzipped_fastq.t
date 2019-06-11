use strict;
use warnings;
use FindBin qw($Bin);
use Test::More;

use_ok 'FASTX::Reader';
my $seq = "$Bin/../data/compressed.fastq.gz";

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
ok( $len > 0 , "[FASTQ.GZ] Received a string as sequence, $len bp long");
$copy =~s/[ACGTNacgtn]//g;
ok(length($copy) == 0, '[FASTQ.GZ] Sequence does not contain unexcpected chars');
ok(length($seq->{seq}) == length($seq->{qual}), '[FASTQ.GZ] Sequence and quality length are the same');

done_testing();
