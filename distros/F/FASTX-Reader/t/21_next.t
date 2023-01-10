use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use FASTX::Reader;
use FASTX::ReaderPaired;
use Data::Dumper;
use Scalar::Util;
# TEST: Parse a regular file as interleaved (error)

my $seq_file = "$RealBin/../data/illumina_1.fq.gz";

# Check required input file
if (! -e $seq_file) {
  print STDERR "Skip test: $seq_file not found\n";
  exit 0;
}

my $data = FASTX::Reader->new({
    filename => "$seq_file"

});


my $s = $data->next();
my $z = $data->getRead();

ok( defined $z->{seq}, "Got sequence (Scalar)");

ok( defined $s->seq, "Got sequence (Blessed)");
isa_ok($s, 'FASTX::Seq');

ok( not (defined $s->{zap}), "Fake attrubute zap not found (Blessed)");
ok( not (defined $z->{zap}), "Fake attrubute zap not found (Scalar)");
done_testing();
