use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;

use FASTX::Reader;
my $seq = "$RealBin/../data/comments.fastq";

# TEST: Retrieves sequence COMMENTS from a FASTQ file

# Check required input file
if (! -e $seq) {
  print STDERR "ERROR TESTING: $seq not found\n";
  exit 0;
}

my $data = FASTX::Reader->new({ filename => "$seq" });

while ($seq = $data->getRead() ) {
	my $comment = $seq->{comment};
	ok( length( $comment ) > 0, "[FASTQ COMMENT] comment found: $comment");

}

done_testing();
