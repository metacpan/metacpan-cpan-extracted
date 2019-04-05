#!perl
use Test2::V0 qw'is float done_testing';
use Math::Lapack::Matrix;
use warnings;
use strict;


my $a = Math::Lapack::Matrix::read_csv("t/slr01.csv", x0 => 1);
my $b = $a->T;

# Convert to list a matrix/vector with dimensions (m,1)
is($a->rows, 23, "Right number of rows");
is($a->columns, 1, "Right number of columns");
my @m = $a->vector_to_list();

is(scalar(@m), 23, "Get right number of elements");
_float($m[0], 11.19999981, "Right element 0");
_float($m[1], 12.5, "Right element 1");
_float($m[2], 12.69999981, "Right element 2");
_float($m[3], 13.10000038, "Right element 3");
_float($m[4], 14.10000038, "Right element 4");
_float($m[5], 14.80000019, "Right element 5");
_float($m[6], 14.39999962, "Right element 6");
_float($m[7], 13.39999962, "Right element 7");
_float($m[8], 14.89999962, "Right element 8");
_float($m[9], 15.60000038, "Right element 9");
_float($m[10], 16.39999962, "Right element 10");
_float($m[11], 17.70000076, "Right element 11");
_float($m[12], 19.60000038, "Right element 12");
_float($m[13], 16.89999962, "Right element 13");
_float($m[14], 14, "Right element 14");
_float($m[15], 14.60000038, "Right element 15");
_float($m[16], 15.10000038, "Right element 16");
_float($m[17], 16.10000038, "Right element 17");
_float($m[18], 16.79999924, "Right element 18");
_float($m[19], 15.19999981, "Right element 19");
_float($m[20], 17, "Right element 20");
_float($m[21], 17.20000076, "Right element 21");
_float($m[22], 18.60000038, "Right element 22");


# Convert to list a matrix/vector with dimensions (1,m)
is($b->rows, 1, "Right number of rows");
is($b->columns, 23, "Right number of columns");
my @l = $b->vector_to_list();

is(scalar(@l), 23, "Get right number of elements");
_float($l[0], 11.19999981, "Right element 0");
_float($l[1], 12.5, "Right element 1");
_float($l[2], 12.69999981, "Right element 2");
_float($l[3], 13.10000038, "Right element 3");
_float($l[4], 14.10000038, "Right element 4");
_float($l[5], 14.80000019, "Right element 5");
_float($l[6], 14.39999962, "Right element 6");
_float($l[7], 13.39999962, "Right element 7");
_float($l[8], 14.89999962, "Right element 8");
_float($l[9], 15.60000038, "Right element 9");
_float($l[10], 16.39999962, "Right element 10");
_float($l[11], 17.70000076, "Right element 11");
_float($l[12], 19.60000038, "Right element 12");
_float($l[13], 16.89999962, "Right element 13");
_float($l[14], 14, "Right element 14");
_float($l[15], 14.60000038, "Right element 15");
_float($l[16], 15.10000038, "Right element 16");
_float($l[17], 16.10000038, "Right element 17");
_float($l[18], 16.79999924, "Right element 18");
_float($l[19], 15.19999981, "Right element 19");
_float($l[20], 17, "Right element 20");
_float($l[21], 17.20000076, "Right element 21");
_float($l[22], 18.60000038, "Right element 22");

done_testing;

sub _float {
  my ($a, $b, $c) = @_;
  is($a, float($b, tolerance => 0.000001), $c);
}
