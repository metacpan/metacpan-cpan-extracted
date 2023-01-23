use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use FASTX::Reader;

# TEST: Retrieves sequences from a test FASTA file

my $seq_file = "$RealBin/../data/test.fasta";

# Check required input file
if (! -e $seq_file) {
  print STDERR "Skip test: $seq_file not found\n";
  exit 0;
}

my $data = FASTX::Reader->new(
	-filename => "$seq_file",
	-loadseqs => 'name'
);

ok(defined $data->{seqs}, 'Retrieved sequences');

my $seq_num = scalar keys %{ $data->{seqs} };
ok($seq_num == 3, "Preloaded 3 sequenses: $seq_num found");

my $c = 0;
for my $seq (keys %{ $data->{seqs} }) {
  $c++;
	ok(defined ${ $data->{seqs} }{$seq}, "[Preloaded.$c] Sequence $seq has a defined value");
	ok(${ $data->{seqs} }{$seq} =~/^[ACGTN]+$/i, "[Preloaded.$c] Sequence $seq has a SEQUENCE value: ${ $data->{seqs} }{$seq}");
}

$data = FASTX::Reader->new({
	filename => "$seq_file",
	loadseqs => 'seq'
});


for my $seq (keys %{ $data->{seqs} }) {
	ok(defined ${ $data->{seqs} }{$seq}, "Sequence $seq has a defined value");
	ok($seq =~/^[ACGTN]+$/i, "Sequence key is a SEQUENCE: " . $seq);
}
ok(defined $data->{seqs}, 'Retrieved sequences');

$data = FASTX::Reader->new({
	filename => "$seq_file",
	loadseqs => 'name'
});


for my $name (keys %{ $data->{seqs} }) {
	ok(defined ${ $data->{seqs} }{$name}, "Sequence $name has a defined value");
	ok($name =~/seq/i, "Hash key is a NAME: " . $name);
}
ok(defined $data->{seqs}, 'Retrieved sequences');

done_testing();
