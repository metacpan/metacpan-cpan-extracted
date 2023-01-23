use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use Data::Dumper;

# This test checks the loadability of the module
# and that the object is correctly blessed as FASTX::Reader

use_ok 'FASTX::Seq';

my $very_new = FASTX::Seq->new(
    -seq  => "CACCA", 
    -name => "seq1", 
    -qual => "IIIII");
ok($very_new->seq eq "CACCA", "seq is CACCA: " . $very_new->seq);
ok($very_new->name eq "seq1", "name is seq1: " . $very_new->name);
ok($very_new->qual eq "IIIII", "qual is IIIII: " . $very_new->qual);
ok($very_new->offset == 33, "default offset is 33: " . $very_new->offset);

my $new_seq = FASTX::Seq->new(
    -seq  => "CACCA", 
    -name => "seq1", 
    -qual => "IIIII",
    -offset => 64);
ok($new_seq->qual eq $very_new->qual, "qual is IIIII for both: " . $new_seq->qual);
ok($new_seq->offset == 64, "custom offset is 64: " . $new_seq->offset);

done_testing();