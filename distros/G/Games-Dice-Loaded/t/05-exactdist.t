use Test::More 0.88;
use Test::Probability;

# Does Test::Probability succeed when you give it *exactly* what it's looking
# for?
dist_ok([(100) x 10], [(1) x 10], 0.01,
	"Test::Probability correctly identifies exact match to even dist");

my @weights = (0 .. 20);
dist_ok([map { $_ * 5 } @weights], \@weights, 0.0001,
	"Test::Probability correctly identifies exact match to uneven dist");

done_testing;
