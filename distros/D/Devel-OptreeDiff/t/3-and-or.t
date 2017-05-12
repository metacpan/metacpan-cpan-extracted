use Test::More tests => 2;
use Devel::OptreeDiff 'fmt_optree_diff';

my @diff = fmt_optree_diff( sub { print @_ and die $! },
			    sub { print @_ or  die $! } );

SKIP: {
    skip 'Devel::OptreeDiff is still including redundant information. TODO', 2;

    is( scalar @diff,
	1,
	'1 chunk detected' );

    is( $diff[0],
	'- /leavesub/lineseq/nextstate*null/and
+ /leavesub/lineseq/nextstate*null/or
',
	'Chunk 1' );
}
