use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use Data::Dumper;

# This test checks the loadability of the module
# and that the object is correctly blessed as FASTX::Reader

use_ok 'FASTX::Seq';
 
#SKIP if seq not found, but expects 2 test
my $newseq = FASTX::Seq->new("ACGTRYSWKMBDHV", "seq1", undef, 
                             "8IIII999999999");
my $original = $newseq->copy();
my $revcompl = $newseq->copy();
# Test rev
ok((length($original->qual) > 0 and $newseq->qual eq $original->qual), "initial qual is defined, and copied: " . $newseq->qual);
ok($newseq->rev()->qual ne "8IIII999999999", "rev/qual is reversed defined: " . $newseq->qual);
ok($newseq->qual ne $original->qual, "qual is changed permanently: " . $newseq->qual);

$revcompl->rc();
is($revcompl->seq, "BDHVKMWSRYACGT", "rc original sequence is BDHVKMWSRYACGT, got: " . $revcompl->seq);
ok($revcompl->qual ne $original->qual, "rc quality is changed: " . $revcompl->qual . " != " . $original->qual);
ok($revcompl->qual eq $newseq->qual, "rc quality is reversed: " . $revcompl->qual . " = " . $newseq->qual);


done_testing();