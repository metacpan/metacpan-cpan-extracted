use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use Data::Dumper;
use FASTX::Reader;
my $seq = "$RealBin/../data/illumina_nocomm.fq";

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

  ok( not (defined $read->{index}), "Index not defined: this file has no comments");
}


done_testing();
