use strict;
use warnings;
use FindBin qw($Bin);
use Test::More;

use_ok 'FASTX::Reader';
my $seq = "$Bin/../scripts/test.fasta";

# Check required input file
if (! -e $seq) {
  print STDERR "Skip test: $seq not found\n";
  exit 0;
}

my $data = FASTX::Reader->new({ filename => "$seq" });
$seq = $data->getRead();
my $copy = $seq->{seq};
ok(length($copy) >0 , 'Received a string as sequence');
$copy =~s/[ACGTNacgtn]//g;
ok(length($copy) == 0, 'Sequence does not contain unexcpected chars');


done_testing();
