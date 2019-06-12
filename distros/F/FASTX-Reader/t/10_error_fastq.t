use strict;
use warnings;
use FindBin qw($Bin);
use Test::More;
use Data::Dumper;
use FASTX::Reader;
my $seq = "$Bin/../data/test.fasta";

# Check required input file
if (! -e $seq) {
  print STDERR "Skip test: $seq not found\n";
  exit 0;
}

my $data = FASTX::Reader->new({ filename => "$seq" });


# CHeck error status before requesting invalid sequence
ok(! defined $data->{status} , "Object has no status (initial state)");
ok(! defined $data->{message}, "Object stored error message (initial state)");
my $getseq = $data->getFastqRead();

ok(! defined $getseq, "FASTQ reader did not return sequence for FASTA file");
# CHeck error status after requesting invalid sequence
ok($data->{status} == 0,          "Object stored bad status: 0");
ok(length($data->{message}) > 0, "Object stored error message: ". $data->{message});

done_testing();
