#!perl

use Test2::V0;

use Math::Lapack::Matrix;

#multiply

note( "A x B" ); #--------------------------------------------------------

my $a = Math::Lapack::Matrix->new([[2, 2]]);
isa_ok $a, ['Math::Lapack::Matrix'], "New returned a matrix A";

my $b = Math::Lapack::Matrix->new([[4, 6, 8], [3, 2, 1]]);
isa_ok $b, ['Math::Lapack::Matrix'], "New returned a matrix B";

my $m = $a->eval_dot($b);

isa_ok $m, ['Math::Lapack::Matrix'], "multiply returned a matrix";

is($m->rows, 1, "Right number of rows");
is($m->columns, 3, "Right number of columns");


is($m->get_element(0,0), 14, "Element correct at 0,0");
is($m->get_element(0,1), 16, "Element correct at 0,1");
is($m->get_element(0,2), 18, "Element correct at 0,2");

note( "A x B'" ); #--------------------------------------------------------

# consider B is transposed
my $c = Math::Lapack::Matrix->new([[4, 3], [6, 2], [8, 1]]);
$m = $a->eval_dot($c, 0, 1);
is($m->rows, 1, "Right number of rows");
is($m->columns, 3, "Right number of columns");
is($m->get_element(0,0), 14, "Element correct at 0,0");
is($m->get_element(0,1), 16, "Element correct at 0,1");
is($m->get_element(0,2), 18, "Element correct at 0,2");

note( "A' x B" ); #--------------------------------------------------------

# consider A is transposed
my $d = Math::Lapack::Matrix->new([[2],[2]]);
$m = $d->eval_dot($b, 1);
is($m->rows, 1, "Right number of rows");
is($m->columns, 3, "Right number of columns");
is($m->get_element(0,0), 14, "Element correct at 0,0");
is($m->get_element(0,1), 16, "Element correct at 0,1");
is($m->get_element(0,2), 18, "Element correct at 0,2");

note( "A' x B'" ); #--------------------------------------------------------

# consider A is transposed
$m = $d->eval_dot($c, 1, 1);
is($m->rows, 1, "Right number of rows");
is($m->columns, 3, "Right number of columns");
is($m->get_element(0,0), 14, "Element correct at 0,0");
is($m->get_element(0,1), 16, "Element correct at 0,1");
is($m->get_element(0,2), 18, "Element correct at 0,2");



done_testing;
