use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;

use FASTX::Reader;
my $seq_file = "$RealBin/../data/comments.fastq";

# TEST: Retrieves seq_fileuence COMMENTS from a FASTQ file

# Check required input file
if (! -e $seq_file) {
  print STDERR "ERROR TESTING: $seq_file not found\n";
  exit 0;
}

my $data = FASTX::Reader->new({ filename => "$seq_file" });

while (my $seq = $data->getRead() ) {
	my $comment = $seq->{comment};
	ok( length( $comment ) > 0, "[FASTQ COMMENT] comment found: $comment");

}

done_testing();
