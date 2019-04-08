#!perl

use Test2::V0 qw'is float done_testing';
use Math::Lapack::Matrix;
use Math::Lapack::Expr;

my $a = Math::Lapack::Matrix->new( 
				[ [1, 2, -10, 15, 17], 
					[3, 4, -12, 13, 1.777]] 
);

my $b = Math::Lapack::Matrix->new(
				[
					[0, 7.77, 8.88889, -10, -15]
				]
);

my $c = Math::Lapack::Matrix->new(
				[
					[12],
					[3],
					[-10],
					[-9]
				]
);

# Sum every element
my $d = $a->sum();
is($d->rows, 1, "Get right number of rows");
is($d->columns, 1, "Get right number of columns");
_float($d->get_element(0,0,), 34.777, "Element correct at 0,0");

# Optional sintax for sum every element
$d = sum($a);
is($d->rows, 1, "Get right number of rows");
is($d->columns, 1, "Get right number of columns");

# Horizontal sum
my $e = $a->sum(0);
is($e->rows, 2, "Get right number of rows");
is($e->columns, 1, "Get right number of columns");
is($e->get_element(0,0), 25, "Element correct at 1,0");
_float($e->get_element(1,0), 9.777, "Element correct at 1,0");

# Optional sintax for horizontal sum
$e = sum($a, 0);
is($e->rows, 2, "Get right number of rows");
is($e->columns, 1, "Get right number of columns");
is($e->get_element(0,0), 25, "Element correct at 0,0");
_float($e->get_element(1,0), 9.777, "Element correct at 1,0");

# Vertical Sum
my $f = $a->sum(1);
is($f->rows, 1, "Get right number of rows");
is($f->columns, 5, "Get right number of columns");
is($f->get_element(0,0), 4, "Element correct at 0,0");
is($f->get_element(0,1), 6, "Element correct at 0,1");
is($f->get_element(0,2), -22, "Element correct at 0,2");
is($f->get_element(0,3), 28, "Element correct at 0,3");
_float($f->get_element(0,4), 18.777, "Element correct at 0,4");

# Optional sintax for vertical sum 
$f = sum($a, 1);
is($f->rows, 1, "Get right number of rows");
is($f->columns, 5, "Get right number of columns");
is($f->get_element(0,0), 4, "Element correct at 0,0");
is($f->get_element(0,1), 6, "Element correct at 0,1");
is($f->get_element(0,2), -22, "Element correct at 0,2");
is($f->get_element(0,3), 28, "Element correct at 0,3");
_float($f->get_element(0,4), 18.777, "Element correct at 0,4");

# Sum operations with vector dimensions (1,m)
my $g = $b->sum;
is($g->rows, 1, "Get right number of rows");
is($g->columns, 1, "Get right number of columns");
_float($g->get_element(0,0), -8.34111, "Element correct at 0,0");


$g = sum($b);
is($g->rows, 1, "Get right number of rows");
is($g->columns, 1, "Get right number of columns");
_float($g->get_element(0,0), -8.34111, "Element correct at 0,0");

$g = sum($b, 0);
is($g->rows, 1, "Get right number of rows");
is($g->columns, 1, "Get right number of columns");
_float($g->get_element(0,0), -8.34111, "Element correct at 0,0");

$g = sum($b, 1);
is($g->rows, 1, "Get right number of rows");
is($g->columns, 5, "Get right number of columns");
_float($g->get_element(0,0), 0, "Element correct at 0,0");
_float($g->get_element(0,1), 7.77, "Element correct at 0,0");
_float($g->get_element(0,2), 8.88889, "Element correct at 0,0");
_float($g->get_element(0,3), -10, "Element correct at 0,0");
_float($g->get_element(0,4), -15, "Element correct at 0,0");

# Sum operations with vector dimensions (1,m)
my $h = $c->sum;
is($h->rows, 1, "Get right number of rows");
is($h->columns, 1, "Get right number of columns");
_float($h->get_element(0,0), -4, "Element correct at 0,0");


#$h = sum($c);
#is($h->rows, 1, "Get right number of rows");
#is($h->columns, 1, "Get right number of columns");
#_float($h->get_element(0,0), -4, "Element correct at 0,0");
#
#$h = sum($c, 1);
#is($h->rows, 1, "Get right number of rows");
#is($h->columns, 1, "Get right number of columns");
#_float($h->get_element(0,0), 4, "Element correct at 0,0");
#
#$h = sum($c, 1);
#is($h->rows, 4, "Get right number of rows");
#is($h->columns, 1, "Get right number of columns");
#_float($h->get_element(0,0), 12, "Element correct at 0,0");
#_float($h->get_element(1,0), 3, "Element correct at 0,0");
#_float($h->get_element(2,0), -10, "Element correct at 0,0");
#_float($h->get_element(3,0), -9, "Element correct at 0,0");

done_testing;
sub _float {
  my ($a, $b, $c) = @_;
  is($a, float($b, tolerance => 0.000001), $c);
}
