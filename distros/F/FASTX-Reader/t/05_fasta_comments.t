use strict;
use warnings;
use FindBin qw($Bin);
use Test::More;
use_ok 'FASTX::Reader';
my $seq = "$Bin/../data/comments.fasta";

# Check required input file
if (! -e $seq) {
  print STDERR "ERROR TESTING: $seq not found\n";
  exit 0;
}

my $data = FASTX::Reader->new({ filename => "$seq" });

while ($seq = $data->getRead() ) {
	my $comment = $seq->{comment};
	ok( length( $comment ) > 0, "[FASTA COMMENT] comment found: $comment");
	my (undef, $len) = split /=/, $comment;

	die "Comment in <$seq> is malformed: expecting len=INT but <$comment> found.\n" unless ($len > 0);
	ok( $len = length($seq->{seq}), "[FASTA COMMENT] Able to parse the comment: $len bp in header matches sequence length");
}

done_testing();
