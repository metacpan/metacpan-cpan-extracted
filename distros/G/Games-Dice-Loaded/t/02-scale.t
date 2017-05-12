use Test::More 0.88;
use Test::Probability;
use Games::Dice::Loaded;

my @weights = (1, 1, 1, 1);
my $d4 = Games::Dice::Loaded->new(1, 1, 1, 1);
is($d4->num_faces, 4, "Fair d4 has four faces");

my @rolls = (0) x @weights;
for my $i (0 .. 4000) {
	my $roll = $d4->roll;
	cmp_ok($roll, ">=", 1, "Roll >= 1");
	cmp_ok($roll, "<=", 4, "Roll <= 4");
	$rolls[$roll - 1]++;
}

dist_ok(\@rolls, \@weights, 0.99, "Fair d4 is fair");

done_testing;
