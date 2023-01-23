use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use FASTX::Reader;
use Data::Dumper;
# TEST: Retrieves sequences from a test FASTA file

my $seq_file = "$RealBin/../data/illumina_1.fq.gz";

# Check required input file
if (! -e $seq_file) {
  print STDERR "Skip test: $seq_file not found\n";
  exit 0;
}

my $data = FASTX::Reader->new(
	-filename => "$seq_file",
	-loadseqs => 'records',
);

isa_ok($data, 'FASTX::Reader', 'FASTX::Reader object created');
my $records = $data->records();

## Postfix dereference introduced at 5.24 (experimental before): not to use in tests
ok(scalar @{ $records } == 7, 'Retrieved 7 records: '. scalar @{ $records });

for my $record (@{ $records }) {
	ok($record->len() > 0, 'Record has a length: ' . $record->len());
	isa_ok($record, 'FASTX::Seq');
	ok($record->seq() =~/^[ACGTN]+$/i, 'Record has a SEQUENCE value: ' . substr($record->seq(),0, 10));
	ok($record->qual() !~/\s/i, 'Record has a QUAL value: ' . substr($record->qual(),0, 10));
}
done_testing();
