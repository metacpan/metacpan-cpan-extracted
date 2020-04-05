use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use Data::Dumper;
use FASTX::Reader;
my $seq_file = "$RealBin/../data/test.fastq";

# Check required input file
if (! -e $seq_file) {
  print STDERR "Skip test: $seq_file not found\n";
  exit 0;
}

my $data = FASTX::Reader->new({ filename => "$seq_file" });

while (my $read = $data->getFastqRead() ) {
	ok( length($read->{qual}) eq length($read->{seq}), "[FASTQ/ALT_PARSER] got sequence and quality for " . $read->{name});

  ok( $data->{status} == 1 , "[FASTQ ALT PARSER] Valid format detected (reader_status=1)");
}


done_testing();
