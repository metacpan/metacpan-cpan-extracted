use strict;
use warnings;
use FindBin qw($Bin);
use Test::More;
use Data::Dumper;
use FASTX::Reader;
*STDIN = *DATA;
my $data = FASTX::Reader->new();

# TEST: Retrieves sequences from a test STDIN FASTQ stream


my $seq = $data->getRead();
my $copy = $seq->{seq};
ok(length($copy) >0 , '[STDIN/implicit] Received a string as sequence');
$copy =~s/[ACGTNacgtn]//g;
ok(length($copy) == 0, '[STDIN/implicit] Sequence does not contain unexcpected chars');
ok(length($seq->{seq}) == length($seq->{qual}), '[STDIN] Sequence and quality length are the same');
ok(length($seq->{comment}) > 0, '[STDIN] First sequence is expected to have a comment');
done_testing();

__DATA__
@SEQ1 with_comment
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
