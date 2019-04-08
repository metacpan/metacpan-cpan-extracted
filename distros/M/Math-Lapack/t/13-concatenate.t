#!perl
use Test2::V0 qw'is float done_testing';
use Math::Lapack::Matrix;
use warnings;
use strict;

my $a = Math::Lapack::Matrix->new([
				[0,1,2,3],
				[6,7,8,9]
		]);

my $b = Math::Lapack::Matrix->new([
				[4,5],
				[10,11]
		]);

my $c = $a->T;

my $d = $b->T;


my $m = Math::Lapack::Matrix::concatenate($a, $b);

_float($m->rows, 2, "Get right number of rows");
_float($m->columns, 6, "Get right number os collumns");

_float($m->get_element(0,0), 0, "Right value 0,0");
_float($m->get_element(0,1), 1, "Right value 0,1");
_float($m->get_element(0,2), 2, "Right value 0,2");
_float($m->get_element(0,3), 3, "Right value 0,3");
_float($m->get_element(0,4), 4, "Right value 0,4");
_float($m->get_element(0,5), 5, "Right value 0,5");
_float($m->get_element(1,0), 6, "Right value 1,0");
_float($m->get_element(1,1), 7, "Right value 1,1");
_float($m->get_element(1,2), 8, "Right value 1,2");
_float($m->get_element(1,3), 9, "Right value 1,3");
_float($m->get_element(1,4), 10,"Right value 1,4");
_float($m->get_element(1,5), 11,"Right value 1,5");

$m = Math::Lapack::Matrix::concatenate($a, $b, 1);
_float($m->rows, 2, "Get right number of rows");
_float($m->columns, 6, "Get right number os collumns");

_float($m->get_element(0,0), 0, "Right value 0,0");
_float($m->get_element(0,1), 1, "Right value 0,1");
_float($m->get_element(0,2), 2, "Right value 0,2");
_float($m->get_element(0,3), 3, "Right value 0,3");
_float($m->get_element(0,4), 4, "Right value 0,4");
_float($m->get_element(0,5), 5, "Right value 0,5");
_float($m->get_element(1,0), 6, "Right value 1,0");
_float($m->get_element(1,1), 7, "Right value 1,1");
_float($m->get_element(1,2), 8, "Right value 1,2");
_float($m->get_element(1,3), 9, "Right value 1,3");
_float($m->get_element(1,4), 10,"Right value 1,4");
_float($m->get_element(1,5), 11,"Right value 1,5");


my $n = $a->append($b);

_float($n->rows, 2, "Get right number of rows");
_float($n->columns, 6, "Get right number os collumns");

_float($n->get_element(0,0), 0, "Right value 0,0");
_float($n->get_element(0,1), 1, "Right value 0,1");
_float($n->get_element(0,2), 2, "Right value 0,2");
_float($n->get_element(0,3), 3, "Right value 0,3");
_float($n->get_element(0,4), 4, "Right value 0,4");
_float($n->get_element(0,5), 5, "Right value 0,5");
_float($n->get_element(1,0), 6, "Right value 1,0");
_float($n->get_element(1,1), 7, "Right value 1,1");
_float($n->get_element(1,2), 8, "Right value 1,2");
_float($n->get_element(1,3), 9, "Right value 1,3");
_float($n->get_element(1,4), 10,"Right value 1,4");
_float($n->get_element(1,5), 11,"Right value 1,5");

$n = $a->append($b, 1);

_float($n->rows, 2, "Get right number of rows");
_float($n->columns, 6, "Get right number os collumns");

_float($n->get_element(0,0), 0, "Right value 0,0");
_float($n->get_element(0,1), 1, "Right value 0,1");
_float($n->get_element(0,2), 2, "Right value 0,2");
_float($n->get_element(0,3), 3, "Right value 0,3");
_float($n->get_element(0,4), 4, "Right value 0,4");
_float($n->get_element(0,5), 5, "Right value 0,5");
_float($n->get_element(1,0), 6, "Right value 1,0");
_float($n->get_element(1,1), 7, "Right value 1,1");
_float($n->get_element(1,2), 8, "Right value 1,2");
_float($n->get_element(1,3), 9, "Right value 1,3");
_float($n->get_element(1,4), 10,"Right value 1,4");
_float($n->get_element(1,5), 11,"Right value 1,5");



##
## CONCATENATION AND APPEND HORIZONTAL
##


my $e = Math::Lapack::Matrix::concatenate($d, $c, 0);
is($e->rows, 6, "Right number of rows");
is($e->columns, 2, "Right number of columns");

_float($e->get_element(0,0), 4, "Right value 0,0");
_float($e->get_element(0,1), 10, "Right value 0,1");
_float($e->get_element(1,0), 5, "Right value 1,0");
_float($e->get_element(1,1), 11, "Right value 1,1");
_float($e->get_element(2,0), 0, "Right value 2,0");
_float($e->get_element(2,1), 6, "Right value 2,1");
_float($e->get_element(3,0), 1, "Right value 3,0");
_float($e->get_element(3,1), 7, "Right value 3,1");
_float($e->get_element(4,0), 2, "Right value 4,0");
_float($e->get_element(4,1), 8, "Right value 4,1");
_float($e->get_element(5,0), 3,"Right value 5,0");
_float($e->get_element(5,1), 9,"Right value 5,1");


my $f = $c->append($d, 0);
is($f->rows, 6, "Right number of rows");
is($f->columns, 2, "Right number of columns");

_float($f->get_element(0,0), 0, "Right value 0,0");
_float($f->get_element(0,1), 6, "Right value 0,1");
_float($f->get_element(1,0), 1, "Right value 1,0");
_float($f->get_element(1,1), 7, "Right value 1,1");
_float($f->get_element(2,0), 2, "Right value 2,0");
_float($f->get_element(2,1), 8, "Right value 2,1");
_float($f->get_element(3,0), 3, "Right value 3,0");
_float($f->get_element(3,1), 9, "Right value 3,1");
_float($f->get_element(4,0), 4, "Right value 4,0");
_float($f->get_element(4,1), 10, "Right value 4,1");
_float($f->get_element(5,0), 5,"Right value 5,0");
_float($f->get_element(5,1), 11,"Right value 5,1");


done_testing;


sub _float {
  my ($a, $b, $c) = @_;
  is($a, float($b, tolerance => 0.00001 ), $c);
}
