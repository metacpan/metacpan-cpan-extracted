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

# Different genetic codes

my $altseq = FASTX::Seq->new(
    -seq => 'TTTGCTTCAACCTAG',
    -id => 'seq1',
);
my $t1 = "FAST*";
my $t2 = "FASTQ";

ok($altseq->translate(1)->seq eq $t1,  "Translation 01 = ". $altseq->translate(11)->seq . ", expected: " . $t1);
ok($altseq->translate(15)->seq eq $t2, "Translation 15 = ". $altseq->translate(15)->seq . ", expected: " . $t2);
done_testing();

__END__

1. The Standard Code (transl_table=1)
By default all transl_table in GenBank flatfiles are equal to id 1, and this is not shown. When transl_table is not equal to id 1, it is shown as a qualifier on the CDS feature.

    AAs  = FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
  Starts = ---M------**--*----M---------------M----------------------------
  Base1  = TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  Base2  = TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  Base3  = TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG


15. Blepharisma Nuclear Code (transl_table=15)
1   AAs  = FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
    AAs  = FFLLSSSSYY*QCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
  Starts = ----------*---*--------------------M----------------------------
  Base1  = TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
  Base2  = TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
  Base3  = TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
