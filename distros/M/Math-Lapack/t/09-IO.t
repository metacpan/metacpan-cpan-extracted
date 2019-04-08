#!perl
use Test2::V0 qw'isa_ok is float done_testing';
use Math::Lapack::Matrix;
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


my $a = Math::Lapack::Matrix::read_csv($file, row_range => [1,22], col => 1);
_float($a->rows, 22, "Get right number of rows");
_float($a->columns, 1, "Get right number of columns");
_float($a->get_element(0,0), 12.5, "Right element 1");
_float($a->get_element(1,0), 12.69999981, "Right element 2");
_float($a->get_element(2,0),13.10000038, "Right element 3");
_float($a->get_element(3,0), 14.10000038, "Right element 4");
_float($a->get_element(4,0), 14.80000019, "Right element 5");
_float($a->get_element(5,0), 14.39999962, "Right element 6");
_float($a->get_element(6,0), 13.39999962, "Right element 7");
_float($a->get_element(7,0), 14.89999962, "Right element 8");
_float($a->get_element(8,0), 15.60000038, "Right element 9");
_float($a->get_element(9,0), 16.39999962, "Right element 10");
_float($a->get_element(10,0), 17.70000076, "Right element 11");
_float($a->get_element(11,0), 19.60000038, "Right element 12");
_float($a->get_element(12,0), 16.89999962, "Right element 13");
_float($a->get_element(13,0), 14, "Right element 14");
_float($a->get_element(14,0), 14.60000038, "Right element 15");
_float($a->get_element(15,0), 15.10000038, "Right element 16");
_float($a->get_element(16,0), 16.10000038, "Right element 17");
_float($a->get_element(17,0), 16.79999924, "Right element 18");
_float($a->get_element(18,0), 15.19999981, "Right element 19");
_float($a->get_element(19,0), 17, "Right element 20");
_float($a->get_element(20,0), 17.20000076, "Right element 21");
_float($a->get_element(21,0), 18.60000038, "Right element 22");

#save matrix
my $s = Math::Lapack::Matrix->new( [ [1, 2, 3], [4, 5, 6] ] );
isa_ok $s, ['Math::Lapack::Matrix'], "New returned a S matrix";
$s->save("t/test");

#read matrix
my $read = Math::Lapack::Matrix->read_matrix("t/test");
isa_ok $read, ['Math::Lapack::Matrix'], "New returned a Read matrix";

_float($read->get_element(0,0), 1, "Element correct at 0,0");
_float($read->get_element(0,1), 2, "Element correct at 0,1");
_float($read->get_element(0,2), 3, "Element correct at 0,2");
_float($read->get_element(1,0), 4, "Element correct at 1,0");
_float($read->get_element(1,1), 5, "Element correct at 1,1");
_float($read->get_element(1,2), 6, "Element correct at 1,2");


done_testing;

sub _float {
  my ($a, $b, $c) = @_;
  is($a, float($b, tolerance => 0.00001 ), $c);
}
