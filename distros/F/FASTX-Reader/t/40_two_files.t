use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use FASTX::Reader;
my $file1    = "$RealBin/../data/file1.fq"; #file1
my $file2    = "$RealBin/../data/file2.fq"; #file2
# TEST: Retrieves sequence COMMENTS from a FASTA file

# Check required input file
if (! -e $file1) {
  print STDERR "ERROR TESTING: $file1 not found\n";
  exit 0;
}
if (! -e $file2) {
  print STDERR "ERROR TESTING: $file2 not found\n";
  exit 0;
}


my $f1 = FASTX::Reader->new({ filename => "$file1" });
my $f2 = FASTX::Reader->new({ filename => "$file2" });

my $c = 0;
while (my $seq1 = $f1->getRead() ) {
	my $seq2 = $f2->getRead();
  $c++;

	ok( $seq1->{name} =~/^file1/, "[FILE1.$c] seqname has <file1>:    $seq1->{name}");
	ok( $seq2->{name} =~/^file2/, "[FILE2.$c] seqname has <file2>: $seq2->{name}");
}

done_testing();
