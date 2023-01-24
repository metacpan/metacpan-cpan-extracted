#!perl

use Test::More tests => 110;
use Math::Matrix::MaybeGSL;

my $m = Matrix->new(10, 20);
isa_ok($m, 'Math::Matrix::MaybeGSL');


my ($rows, $cols) = $m->dim();
is $rows => 10;
is $cols => 20;


$m->assign(1, 1, 100);
is $m->element(1,1), 100;
is $m->element(1,2), 0;

my $m2 = Matrix->new_from_cols( [[1, 2], [3, 4]]);
isa_ok($m, 'Math::Matrix::MaybeGSL');

is $m2->element(1,1), 1;
is $m2->element(2,1), 2;
is $m2->element(1,2), 3;
is $m2->element(2,2), 4;

is $m2->det, -2, "determinant is 1*4-2*3=-2";


my $m3 = Matrix->new_from_cols( [[5, 6], [7, 8]]);
my $m4 = $m2->hconcat($m3);
isa_ok($m4, 'Math::Matrix::MaybeGSL');
is $m4->element(1,1), 1;
is $m4->element(2,1), 2;
is $m4->element(1,2), 3;
is $m4->element(2,2), 4;

is $m4->element(1,3), 5;
is $m4->element(2,3), 6;
is $m4->element(1,4), 7;
is $m4->element(2,4), 8;


my $m5 = $m2->vconcat($m3);
isa_ok($m5, 'Math::Matrix::MaybeGSL');
is $m5->element(1,1), 1;
is $m5->element(2,1), 2;
is $m5->element(1,2), 3;
is $m5->element(2,2), 4;

is $m5->element(3,1), 5;
is $m5->element(4,1), 6;
is $m5->element(3,2), 7;
is $m5->element(4,2), 8;


my $m6 = $m2 * $m3;
isa_ok($m6, 'Math::Matrix::MaybeGSL');
#    23   31
#    34   46
is $m6->element(1,1), 23;
is $m6->element(1,2), 31;
is $m6->element(2,1), 34;
is $m6->element(2,2), 46;

my $m61 = $m6 * 2;
isa_ok($m61, 'Math::Matrix::MaybeGSL');
is $m61->element(1,1), 23 * 2;
is $m61->element(1,2), 31 * 2;
is $m61->element(2,1), 34 * 2;
is $m61->element(2,2), 46 * 2;

my $m62 = 2 * $m6;
isa_ok($m62, 'Math::Matrix::MaybeGSL');
is $m62->element(1,1), 23 * 2;
is $m62->element(1,2), 31 * 2;
is $m62->element(2,1), 34 * 2;
is $m62->element(2,2), 46 * 2;


my $m7 = $m6->each( sub { $_ = shift; ($_ + $_%2) / 2 });
isa_ok($m7, 'Math::Matrix::MaybeGSL');
is $m7->element(1,1), 12;
is $m7->element(1,2), 16;
is $m7->element(2,1), 17;
is $m7->element(2,2), 23;

my ($v, $r, $c) = $m7->max();
is $v, 23;
is $r, 2;
is $c, 2;

($v, $r, $c) = $m7->min();
is $v, 12;
is $r, 1;
is $c, 1;


my $m8 = Matrix->new_from_rows( [[1, 2], [3, 4]]);
isa_ok($m8, 'Math::Matrix::MaybeGSL');

is $m8->element(1,1), 1;
is $m8->element(2,1), 3;
is $m8->element(1,2), 2;
is $m8->element(2,2), 4;

$m8->write("tmp-mat");

ok -f "tmp-mat";

is_deeply [$m8->as_list], [1, 2, 3, 4];


my $m9 = Matrix->read("tmp-mat");
isa_ok($m9, 'Math::Matrix::MaybeGSL');

is $m9->element(1,1), 1;
is $m9->element(2,1), 3;
is $m9->element(1,2), 2;
is $m9->element(2,2), 4;

unlink "tmp-mat" if -f "tmp-mat";

my $m10 = Matrix->new_from_rows( [[1, 2], [3, 4]]);
isa_ok($m10, 'Math::Matrix::MaybeGSL');

my $m11 = $m10->row(1);
isa_ok($m11, 'Math::Matrix::MaybeGSL');

is $m11->element(1,1), 1;
is $m11->element(1,2), 2;

my $m12 = Matrix->new_from_rows( [[0, 0, 1], [0, 1, 0]]);
isa_ok($m12, 'Math::Matrix::MaybeGSL');

my @zeros = $m12->find_zeros();

is scalar(@zeros), 4;
is $zeros[0]->[0], 1;
is $zeros[0]->[1], 1;
is $zeros[1]->[0], 1;
is $zeros[1]->[1], 2;
is $zeros[2]->[0], 2;
is $zeros[2]->[1], 1;
is $zeros[3]->[0], 2;
is $zeros[3]->[1], 3;

my $m13 = $m2 + $m3;
isa_ok($m13, 'Math::Matrix::MaybeGSL');
#     6   10
#     8   12
is $m13->element(1,1),  6;
is $m13->element(1,2), 10;
is $m13->element(2,1),  8;
is $m13->element(2,2), 12;

my $m14 = Matrix->new_from_rows( [[1, 2], [3, 4]]);
isa_ok($m14, 'Math::Matrix::MaybeGSL');

my $m15 = $m14->transpose();
isa_ok($m15, 'Math::Matrix::MaybeGSL');

is $m15->element(1,1), 1;
is $m15->element(1,2), 3;
is $m15->element(2,1), 2;
is $m15->element(2,2), 4;

my $m16 = Matrix->new_from_rows( [[1, 2, 3], [4, 5, 6]]);
isa_ok($m16, 'Math::Matrix::MaybeGSL');

my $m17 = $m16->transpose();
isa_ok($m17, 'Math::Matrix::MaybeGSL');

is join(',', $m17->dim()), '3,2';
is $m17->element(1,1), 1;
is $m17->element(1,2), 4;
is $m17->element(2,1), 2;
is $m17->element(2,2), 5;
is $m17->element(3,1), 3;
is $m17->element(3,2), 6;

my $m18 = Matrix->new_from_cols( [[1, 2, 3], [4, 5, 6]]);
isa_ok($m18, 'Math::Matrix::MaybeGSL');

my $m19 = $m18->transpose();
isa_ok($m19, 'Math::Matrix::MaybeGSL');

is join(',', $m19->dim()), '2,3';
is $m19->element(1,1), 1;
is $m19->element(1,2), 2;
is $m19->element(1,3), 3;
is $m19->element(2,1), 4;
is $m19->element(2,2), 5;
is $m19->element(2,3), 6;

1;
