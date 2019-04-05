#!perl
use Test2::V0 qw'is float done_testing';
use Math::Lapack::Matrix;
use Math::Lapack::Expr;
use warnings;
use strict;

my $a = Math::Lapack::Matrix->new([
				[0, 1, 2, 3],
				[6, 7, 8, 9],
				[7, 3, -1, 4]
		]);

my $b = Math::Lapack::Matrix->new(
		[
				[7],
				[9],
				[15],
				[0],
				[3],
				[4],
				[2]
		]
);

my $max_a = $a->get_max();
my $max_b = $b->get_max();
my $min_a = $a->get_min();
my $min_b = $b->get_min();

my $mean_a = $a->mean();
my $mean_b = $b->mean();



_float($max_a, 9, "Get right max of Matrix A");
_float($max_b, 15, "Get right max of Matrix B");
_float($min_a, -1, "Get right min of Matrix A");
_float($min_b, 0, "Get right min of Matrix B");

_float($mean_a, 4.0833333, "Get right mean of elements in Matrix A");
_float($mean_b, 5.714285714, "Get right mean of elements in Matrix B");


my $a_data = $a->norm_mean();

_float($a->get_element(0,0), -0.619047571, "Norm by Mean: Right element 0,0");
_float($a->get_element(1,0), 0.238095286, "Norm by Mean: Right element 1,0");
_float($a->get_element(2,0), 0.380957143, "Norm by Mean: Right element 2,0");

_float($a->get_element(0,1), -0.444444333, "Norm by Mean: Right element 0,1");
_float($a->get_element(1,1), 0.555555667, "Norm by Mean: Right element 1,1");
_float($a->get_element(2,1), -0.11111111, "Norm by Mean: Right element 2,1");

_float($a->get_element(0,2), -.111111111, "Norm by Mean: Right element 0,2");
_float($a->get_element(1,2), 0.555555556, "Norm by Mean: Right element 1,2");
_float($a->get_element(2,2), -.444444444, "Norm by Mean: Right element 2,2");

_float($a->get_element(0,3), -0.388888333, "Norm by Mean: Right element 0,3");
_float($a->get_element(1,3), 0.611111117, "Norm by Mean: Right element 1,3");
_float($a->get_element(2,3), -0.222222217, "Norm by Mean: Right element 2,3");

_float($a_data->rows, 2, "Right number of rows of a_data");
_float($a_data->columns, 4, "Right number of rows of a_data");

# mean and (max - min) of col 0
_float($a_data->get_element(0,0), 4.33333333, "Norm by Mean: Right mean of col 0");
_float($a_data->get_element(1,0), 7, "Norm by Mean: Right max - min of col 0");

# mean and (max - min) of col 1 
_float($a_data->get_element(0,1), 3.666666, "Norm by Mean: Right mean of col 1");
_float($a_data->get_element(1,1), 6, "Norm by Mean: Right max - min of col 1");

# mean and (max - min) of col 2
_float($a_data->get_element(0,2), 3, "Norm by Mean: Right mean of col 2");
_float($a_data->get_element(1,2), 9, "Norm by Mean: Right max - min of col 2");

# mean and (max - min) of col 3
_float($a_data->get_element(0,3), 5.33333333, "Norm by Mean: Right mean of col 3");
_float($a_data->get_element(1,3), 6, "Norm by Mean: Right max - min of col 3");

# Reset values
$a = Math::Lapack::Matrix->new([
				[0, 1, 2, 3],
				[6, 7, 8, 9],
				[7, 3, -1, 4]
]);


$a->norm_mean( by => $a_data );

_float($a->get_element(0,0), -0.619047571, "Norm by Mean: Right element 0,0");
_float($a->get_element(1,0), 0.238095286, "Norm by Mean: Right element 1,0");
_float($a->get_element(2,0), 0.380957143, "Norm by Mean: Right element 2,0");

_float($a->get_element(0,1), -0.444444333, "Norm by Mean: Right element 0,1");
_float($a->get_element(1,1), 0.555555667, "Norm by Mean: Right element 1,1");
_float($a->get_element(2,1), -0.11111111, "Norm by Mean: Right element 2,1");

_float($a->get_element(0,2), -.111111111, "Norm by Mean: Right element 0,2");
_float($a->get_element(1,2), 0.555555556, "Norm by Mean: Right element 1,2");
_float($a->get_element(2,2), -.444444444, "Norm by Mean: Right element 2,2");

_float($a->get_element(0,3), -0.388888333, "Norm by Mean: Right element 0,3");
_float($a->get_element(1,3), 0.611111117, "Norm by Mean: Right element 1,3");
_float($a->get_element(2,3), -0.222222217, "Norm by Mean: Right element 2,3");


# Reset values
$a = Math::Lapack::Matrix->new([
				[0, 1, 2, 3],
				[6, 7, 8, 9],
				[7, 3, -1, 4]
		]);

my $std = $a->norm_std_deviation();

_float($a->get_element(0,0), -1.14458535, "Norm by std deviation: Right element 0,0");
_float($a->get_element(1,0), 0.440226354, "Norm by std deviation: Right element 1,0");
_float($a->get_element(2,0), 0.704361637, "Norm by std deviation: Right element 2,0");

_float($a->get_element(0,1), -0.872871343, "Norm by std deviation: Right element 0,1");
_float($a->get_element(1,1), 1.09108967, "Norm by std deviation: Mean: Right element 1,1");
_float($a->get_element(2,1), -0.218217672, "Norm by std deviation: Mean: Right element 2,1");

_float($a->get_element(0,2), -0.21821789, "Norm by std deviation: Right element 0,2");
_float($a->get_element(1,2), 1.091089451, "Norm by std deviation: Right element 1,2");
_float($a->get_element(2,2), -0.872871561, "Norm by std deviation: Right element 2,2");

_float($a->get_element(0,3), -0.72586625, "Norm by std deviation: Right element 0,3");#forced
_float($a->get_element(1,3), 1.140652432, "Norm by std deviation: Right element 1,3");
_float($a->get_element(2,3), -0.414781289, "Norm by std deviation: Right element 2,3");


_float($std->rows, 2, "Right number of rows of a_data");
_float($std->columns, 4, "Right number of rows of a_data");

# mean and (max - min) of col 0
_float($std->get_element(0,0), 4.33333333, "Norm by Std: Right mean of col 0");
_float($std->get_element(1,0), 3.785945501, "Norm by Std: Right std of col 0");

# mean and (max - min) of col 1 
_float($std->get_element(0,1), 3.666666, "Norm by Std: Right mean of col 1");
_float($std->get_element(1,1), 3.055053082, "Norm by Std: Right std of col 1");

# mean and (max - min) of col 2
_float($std->get_element(0,2), 3, "Norm by Std: Right mean of col 2");
_float($std->get_element(1,2), 4.582575695, "Norm by Std: Right std of col 2");

# mean and (max - min) of col 3
_float($std->get_element(0,3), 5.33333333, "Norm by Std: Right mean of col 3");
_float($std->get_element(1,3), 3.214550254, "Norm by Std: Right std of col 3");

# Reset values
$a = Math::Lapack::Matrix->new([
				[0, 1, 2, 3],
				[6, 7, 8, 9],
				[7, 3, -1, 4]
		]);

$a->norm_std_deviation( by => $std );

_float($a->get_element(0,0), -1.14458535, "Norm by std deviation: Right element 0,0");
_float($a->get_element(1,0), 0.440226354, "Norm by std deviation: Right element 1,0");
_float($a->get_element(2,0), 0.704361637, "Norm by std deviation: Right element 2,0");

_float($a->get_element(0,1), -0.872871343, "Norm by std deviation: Right element 0,1");
_float($a->get_element(1,1), 1.09108967, "Norm by std deviation: Mean: Right element 1,1");
_float($a->get_element(2,1), -0.218217672, "Norm by std deviation: Mean: Right element 2,1");

_float($a->get_element(0,2), -0.21821789, "Norm by std deviation: Right element 0,2");
_float($a->get_element(1,2), 1.091089451, "Norm by std deviation: Right element 1,2");
_float($a->get_element(2,2), -0.872871561, "Norm by std deviation: Right element 2,2");

_float($a->get_element(0,3), -0.72586625, "Norm by std deviation: Right element 0,3");#forced
_float($a->get_element(1,3), 1.140652432, "Norm by std deviation: Right element 1,3");
_float($a->get_element(2,3), -0.414781289, "Norm by std deviation: Right element 2,3");


done_testing;

sub _float {
  my ($a, $b, $c) = @_;
  is($a, float($b, tolerance => 0.00001 ), $c);
}
