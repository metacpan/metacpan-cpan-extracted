use strict;
use warnings;
use FindBin qw($Bin);
use Test::More;
use Data::Dumper;
use_ok 'FASTX::Reader';
*STDIN = *DATA;
my $data = FASTX::Reader->new();

# Retrieve first sequence

my $seq = $data->getRead({  filename => '{{STDIN}}' });
my $copy = $seq->{seq};
ok(length($copy) >0 , 'Received a string as sequence');
$copy =~s/[ACGTNacgtn]//g;
ok(length($copy) == 0, 'Sequence does not contain unexcpected chars');
ok(length($seq->{seq}) == length($seq->{qual}), 'Sequence and quality length are the same');

done_testing();

__DATA__
@SEQ1
ACGTACGTACGTAGCTGATCGATCGTACGTAGCTGACA
+
IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
@SEQ2
NNNNNCGTACGTAGCTGATCGATCGTACGTAGCTGACA
+
!!!!!AIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
@SEQ3
ACGTACGTACGTAGCTGATCGATCGTACGTAGCTGACN
+
IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
