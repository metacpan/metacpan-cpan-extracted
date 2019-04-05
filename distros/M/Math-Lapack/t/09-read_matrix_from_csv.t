#!perl
use Test2::V0 qw'is float done_testing';
use Math::Lapack::Matrix;
use Math::Lapack::Expr;
use warnings;
use strict;

my $file = 't/slr01.csv';
my $m = Math::Lapack::Matrix::read_csv($file);

_float($m->rows, 23, "Get right number of rows");
_float($m->columns, 2, "Get right number os collumns");

_float($m->get_element(0,0), 12.399999, "Right value 0,0");
_float($m->get_element(0,1), 11.199999, "Right value 0,1");
_float($m->get_element(1,0), 14.3000, "Right value 0,2");
_float($m->get_element(1,1), 12.5, "Right value 0,3");
#_float($m->get_element(0,4), 4, "Right value 0,4");
#_float($m->get_element(0,5), 5, "Right value 0,5");
#_float($m->get_element(1,0), 6, "Right value 1,0");
#_float($m->get_element(1,1), 7, "Right value 1,1");
#_float($m->get_element(1,2), 8, "Right value 1,2");
#_float($m->get_element(1,3), 9, "Right value 1,3");
#_float($m->get_element(1,4), 10,"Right value 1,4");
#_float($m->get_element(1,5), 11,"Right value 1,5");


my $a = Math::Lapack::Matrix::read_csv($file, x0 => 1, y0 => 1);
_float($a->rows, 22, "Get right number of rows");
_float($a->columns, 1, "Get right number of columns");
_float($a->get_element(0,0), 12.5, "Right value 0,0");
_float($a->get_element(1,0), 12.69999999, "Right value 1,0");
_float($a->get_element(21,0), 18.600000, "Right value 22,0");

done_testing;

sub _float {
  my ($a, $b, $c) = @_;
  is($a, float($b, tolerance => 0.00001 ), $c);
}
