use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use Data::Dumper;
use FASTX::Reader;
my $seq = "$RealBin/../data/illumina_1.fq.gz";

# Check required input file
if (! -e $seq) {
  print STDERR "Skip test: $seq not found\n";
  exit 0;
}

my $data = FASTX::Reader->new({ filename => "$seq" });

while (my $read = $data->getIlluminaRead() ) {
	ok( length($read->{qual}) eq length($read->{seq}),
    "[ILLUMINA] got sequence and quality for " . $read->{name});

  ok( $data->{status} == 1 ,
    "[ILLUMINA] Valid format detected (reader_status=1)");

  ok( length($read->{instrument}) > 0, "Received instrument: $read->{instrument}");
  ok( length($read->{index}) > 0, "Received index: $read->{index}");
  ok( length($read->{tile}) > 0, "Received tile: $read->{tile}");
  ok( length($read->{index}) > 0, "Received index: $read->{index}");
}


done_testing();
