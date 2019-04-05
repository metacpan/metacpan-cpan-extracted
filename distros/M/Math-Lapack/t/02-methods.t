#!perl

use Test2::V0;
use Math::Lapack::Matrix;

my $a = Math::Lapack::Matrix->new(
				[
					[ 0,  1, 2],
					[ 3,  6, 7],
					[ 8,  9, 7],
					[ 3, -1, 4]
				]
);

my ($m, $n) = $a->shape;
is($m, $a->rows, "Right number of rows");
is($n, $a->columns, "Right number of rows");

my $max = $a->get_max;
_float($max, 9, "Right max");

my $min = $a->get_min;
_float($min, -1, "Right max");

my $mean = $a->mean();
_float($mean, 4.0833333, "Right mean");

my $s = $a->std_deviation();
_float($s, 3.2879486, "Right standard deviation");

$a->set_element(2,2,-1.33);
_float($a->get_element(2,2), -1.33, "Correct element after set the value");

done_testing;


sub _float {
  my ($a, $b, $c) = @_;
  is($a, float($b, tolerance => 0.000001), $c);
}
