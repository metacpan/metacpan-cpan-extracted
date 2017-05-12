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
	$rolls[$roll - 1]++;
}

ok(!Test::Probability::fits_distribution(\@rolls, [1, 1, 1, 1, 1], 0.9),
	"Test::Probability correctly identifies failures");

done_testing;
