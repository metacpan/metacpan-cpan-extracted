use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use Data::Dumper;
use FASTX::Reader;
*STDIN = *DATA;
my $data = FASTX::Reader->new();

# TEST: Retrieves sequences from a test STDIN FASTQ stream (explicitly requested via {{STDIN}})


my $seq = $data->getRead({  filename => '{{STDIN}}' });
my $copy = $seq->{seq};
ok(length($copy) >0 , '[STDIN/explicit] Received a string as sequence');
$copy =~s/[ACGTNacgtn]//g;
ok(length($copy) == 0, '[STDIN/explicit] Sequence does not contain unexcpected chars');
ok(length($seq->{seq}) == length($seq->{qual}), '[STDIN] Sequence and quality length are the same');
ok(length($seq->{comment}) > 0, '[STDIN/explicit] First sequence is expected to have a comment');
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
