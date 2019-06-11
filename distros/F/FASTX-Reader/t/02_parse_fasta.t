use strict;
use warnings;
use FindBin qw($Bin);
use Test::More;

use_ok 'FASTX::Reader';
my $seq = "$Bin/../data/test.fasta";

# Check required input file
if (! -e $seq) {
  print STDERR "Skip test: $seq not found\n";
  exit 0;
}

my $data = FASTX::Reader->new({ filename => "$seq" });
$seq = $data->getRead();
my $copy = $seq->{seq};
my $len = length($copy);
ok($len > 0 , "[FASTA] Received a string as sequence, $len bp long");
$copy =~s/[ACGTNacgtn]//g;
ok(length($copy) == 0, '[FASTA] Sequence does not contain unexcpected chars');


done_testing();
