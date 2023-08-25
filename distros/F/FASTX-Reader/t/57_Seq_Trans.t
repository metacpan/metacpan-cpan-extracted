use 5.012;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use File::Spec::Functions;
use FASTX::Seq;
use Data::Dumper;
# TEST: Parse a regular file as interleaved (error)


my $seqobj = FASTX::Seq->new(
    -seq => 'ATGATG',
    -id => 'seq1',
);
is($seqobj->is_fasta(), 1, "FASTA record detected = ". $seqobj->is_fasta());
my $orf = $seqobj->translate(11);
ok($orf->is_fasta() == 1, "FASTA record detected = ". $orf->is_fasta());
ok($orf->seq eq 'MM', "Sequence = ". $orf->seq());

done_testing();
