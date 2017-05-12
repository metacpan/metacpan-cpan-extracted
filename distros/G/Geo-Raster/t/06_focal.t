use POSIX;
use Test::More qw(no_plan);

BEGIN { 
    use_ok( 'Geo::Raster' );
}

# test focal methods: set, get, sum now mean, variance, count, count_of, range, 
# global focal: sum, mean, variance, count, count_of

my $grid = new Geo::Raster 10,10;

my @mask = ([1,0,1],[0,1,0],[1,1,1]);

$grid->set(4,4,\@mask);

my $mask = $grid->get(4,4,1);

is_deeply($mask, \@mask, "do we get what we set?");

@mask = ([1,1,1],[1,0,1],[1,1,1]);

my $sum = $grid->focal_sum(\@mask,4,4);
is($sum, 5, "focal sum for a cell");

my $mean = $grid->focal_mean(\@mask,4,4);
is($mean, 0.625, "focal mean for a cell");

my $variance = $grid->focal_variance(\@mask,4,4);
my $count = $grid->focal_count(\@mask,4,4);
my $count_of = $grid->focal_count_of(\@mask,1,4,4);
my $range = $grid->focal_range(\@mask,4,4);
my $g = $grid->convolve(\@mask,4,4);

$sum = $grid->focal_sum(\@mask);

is($sum->get(4,4), 5, "focal sum for a grid");

$variance = $grid->focal_variance(\@mask);
$count = $grid->focal_count(\@mask);
$count_of = $grid->focal_count_of(\@mask,1);
$g = $grid->convolve(\@mask);

$grid->focal_sum(\@mask);

is($grid->get(4,4), 5, "focal sum for a grid self");

$grid = new Geo::Raster 10,10;
$grid->set(0);
$grid->set(5,5,9);
$grid->spread([[1,1,1],[1,1,1],[1,1,1]]);
for $i (4..6) {
    for $j (4..6) {
        is($grid->get($i,$j), 1, "spread $i $j");
    }
}
$grid = new Geo::Raster 10,10;
$grid->set(0);
$grid->set(5,5,1);
$mask = [[1,1,1],[1,1,1],[1,1,1]];
$grid->spread_random($mask);
is($grid->focal_sum($mask,5,5), 1, "spread_random");

