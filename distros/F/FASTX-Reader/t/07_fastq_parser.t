use strict;
use warnings;
use FindBin qw($Bin);
use Test::More;

use_ok 'FASTX::Reader';
my $seq = "$Bin/../data/test.fastq";

# Check required input file
if (! -e $seq) {
  print STDERR "Skip test: $seq not found\n";
  exit 0;
}

my $data = FASTX::Reader->new({ filename => "$seq" });

while (my $read = $data->getFastqRead() ) {
	ok( length($read->{qual}) eq length($read->{seq}), "[FASTQ ALT PARSER] Ok: got sequence and quality");	
}

done_testing();
