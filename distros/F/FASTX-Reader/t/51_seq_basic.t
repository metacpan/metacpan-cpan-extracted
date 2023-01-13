use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use Data::Dumper;

# This test checks the loadability of the module
# and that the object is correctly blessed as FASTX::Reader

use_ok 'FASTX::Seq';

#SKIP if seq not found, but expects 2 test
my $newseq = FASTX::Seq->new("CACCA", "seq1", undef, "IIIII");
print Dumper $newseq;
ok($newseq->seq, "seq is defined: " . $newseq->seq);
ok($newseq->name, "name is defined: " . $newseq->name);
ok(not (defined $newseq->comment), "comment not defined");
ok($newseq->qual, "qual is defined: " . $newseq->qual);

eval {
    my $badseq = FASTX::Seq->new("CACCA", "seq1", undef, "III");
};

ok($@, "error on quality length mismatch");
ok(length($FASTX::Seq::DEFAULT_QUALITY) == 1, "default quality is 1 char long: " . $FASTX::Seq::DEFAULT_QUALITY);
done_testing();