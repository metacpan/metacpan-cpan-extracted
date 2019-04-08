#!perl
use Test2::V0 qw'is float done_testing';

use Math::Lapack::Matrix;
use Math::Lapack::Expr;

my $A = Math::Lapack::Matrix->new( [[1, 2, 3], [4, 5, 6]]);
my $B = Math::Lapack::Matrix->new( [[1, 2, 3]]);
my $s = 5;

# broadcasting of sum of matrices
my $c = $A + $B;

_float($c->get_element(0,0), 2, "correct element at position 0,0");
_float($c->get_element(0,1), 4, "correct element at position 0,1");
_float($c->get_element(0,2), 6, "correct element at position 0,2");
_float($c->get_element(1,0), 5, "correct element at position 1,0");
_float($c->get_element(1,1), 7, "correct element at position 1,1");
_float($c->get_element(1,2), 9, "correct element at position 1,2");

my $d = $A + $s;

_float($d->get_element(0,0), 6, "correct element at position 0,0");
_float($d->get_element(0,1), 7, "correct element at position 0,1");
_float($d->get_element(0,2), 8, "correct element at position 0,2");
_float($d->get_element(1,0), 9, "correct element at position 1,0");
_float($d->get_element(1,1), 10, "correct element at position 1,1");
_float($d->get_element(1,2), 11, "correct element at position 1,2");

my $e = $d - $s;
_float($e->get_element(0,0), $A->get_element(0,0), "Correct element after subtraction");

#my $f = $A + $B + $e;
#_float($f->get_element(0,0), 8, "Correct element after multiple additions");

my $g = $A x Math::Lapack::Matrix->new([[1],[2],[3]]);
_float($g->get_element(0,0), 14, "correct element at position 0,0");
_float($g->get_element(1,0), 32, "correct element at position 1,0");

my $h = $A x transpose($B);
_float($h->get_element(0,0), 14, "correct element at position 0,0");
_float($h->get_element(1,0), 32, "correct element at position 1,0");

my $i = Math::Lapack::Matrix->new([[8]]) x transpose(Math::Lapack::Matrix->new([[3],[4],[5]]));
_float($i->get_element(0,0), 24, "correct element at position 0,0");
_float($i->get_element(0,1), 32, "correct element at position 0,1");
_float($i->get_element(0,2), 40, "correct element at position 0,2");

#failing in this
my $j = transpose(Math::Lapack::Matrix->new([[4,5,6,7]])) x Math::Lapack::Matrix->new([[9]]);
_float($j->get_element(0,0), 36, "correct element at position 0,0");
_float($j->get_element(1,0), 45, "correct element at position 0,1");
_float($j->get_element(2,0), 54, "correct element at position 0,2");
_float($j->get_element(3,0), 63, "correct element at position 0,3");

my $k = transpose(Math::Lapack::Matrix->new([[1,2]])) x transpose(Math::Lapack::Matrix->new([[3],[4]]));
_float($k->get_element(0,0), 3, "correct element at position 0,0");
_float($k->get_element(0,1), 4, "correct element at position 0,1");
_float($k->get_element(1,0), 6, "correct element at position 1,0");
_float($k->get_element(1,1), 8, "correct element at position 1,1");


done_testing;

sub _float {
  my ($a, $b, $c) = @_;
  is($a, float($b, tolerance => 0.000001), $c);
}






