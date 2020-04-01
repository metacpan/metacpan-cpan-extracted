use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use Data::Dumper;
use FASTX::Reader;
my $seq = "$RealBin/../data/bad.fastq";

# Check required input file
if (! -e $seq) {
  die "Skip test: $seq not found\n";
}

my $data = FASTX::Reader->new({ filename => "$seq" });

my $read = $data->getFastqRead();
ok( $data->{status} == 0 , "[FASTQ ALT PARSER] Ok: detected problem in bad file (status = 0)");
ok( length($data->{message}) > 0 , "[FASTQ ALT PARSER] Ok: detected problem in bad file: " . $data->{message});


done_testing();
