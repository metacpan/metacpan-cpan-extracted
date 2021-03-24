use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use FASTX::Reader;
my $file1    = "$RealBin/../data/file1.fa"; #S000
my $file2    = "$RealBin/../data/file2.fa"; #
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


	ok( $seq1->{name} =~/^file1/,  "[File1.$c]  First file seqname is: $seq1->{name} (exp file1)");
	ok( $seq2->{name} =~/^file2/i, "[File2.$c] Second file seqname is: $seq2->{name} (exp file2)");
}

done_testing();
