use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use Data::Dumper;

use Scalar::Util qw(blessed);
# This test checks the loadability of the module
# and that the object is correctly blessed as FASTX::Reader

use_ok 'FASTX::Reader';

my $seq_file = "$RealBin/../data/test.fasta";

# Check required input file
if (! -e $seq_file) {
  print STDERR "Skip test: $seq_file not found\n";
  exit 0;
}

my $data = FASTX::Reader->new({ filename => "$seq_file" });
my $seq_object = $data->next();

ok(blessed($seq_object) and $seq_object->isa('FASTX::Seq'), "[READER/Seq] sequence is defined");

my $seq = $seq_object->seq;
my $len = length($seq);

# Check that the sequence has a length (i.e. non null string)
ok($len > 0 , "[READER/Seq] Received a string as sequence, $len bp long");

done_testing();
