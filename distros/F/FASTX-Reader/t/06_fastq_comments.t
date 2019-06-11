use strict;
use warnings;
use FindBin qw($Bin);
use Test::More;

use_ok 'FASTX::Reader';
my $seq = "$Bin/../data/comments.fastq";

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
