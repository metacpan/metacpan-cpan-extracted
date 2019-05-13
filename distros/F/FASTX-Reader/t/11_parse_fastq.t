use strict;
use warnings;
use FindBin qw($Bin);
use Test::More;

use_ok 'FASTX::Reader';
my $seq = "$Bin/../scripts/test.fastq";

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
ok(length($copy) >0 , 'Received a string as sequence');
$copy =~s/[ACGTNacgtn]//g;
ok(length($copy) == 0, 'Sequence does not contain unexcpected chars');
ok(length($seq->{seq}) == length($seq->{qual}), 'Sequence and quality length are the same');

done_testing();
