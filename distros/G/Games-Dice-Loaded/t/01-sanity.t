use Test::More 0.88;
use Test::Probability;
use Games::Dice::Loaded;

# Plato woz ere
my @weights = (1/6, 1/6, 1/2, 1/12, 1/12);
my $die = Games::Dice::Loaded->new(@weights);
is $die->num_faces, 5, "Die has one face per weight";
my @rolls = (0) x @weights;
for my $i (0 .. 12000) {
	my $roll = $die->roll;
	cmp_ok $roll, ">=", 1, "Roll $roll >= 1";
	cmp_ok $roll, "<=", 5, "Roll $roll <= 5";
	$rolls[$roll - 1]++;
}

dist_ok(\@rolls, \@weights, 0.99, "Die rolls match expected distribution");

done_testing;
