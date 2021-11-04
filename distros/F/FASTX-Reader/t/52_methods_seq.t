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

my $rev = $newseq->rc();
is($rev->seq, "BDHVKMWSRYACGT", "rc sequence");
is($newseq->rc()->seq, "ACGTRYSWKMBDHV", "rc again");


done_testing();