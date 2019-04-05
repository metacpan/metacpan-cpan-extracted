#!perl

use Test2::V0 qw'is float done_testing';

use Math::Lapack::Matrix;

my $m = Math::Lapack::Matrix->new( [    
                                    [1, 2, 3, 4, 5, 6],
                                    [7, 8, 9, 10, 11, 12],
                                    [13, 14, 15, 16, 17, 18]
                                    ]);

# Get first row, row indice 0
my $a = $m->slice(row_range => [0,0]);
_float($a->rows, 1, "Get right number of rows");
_float($a->columns, 6, "Get right number of cols");
_float($a->get_element(0,0), 1, "Get right value 0,0");
_float($a->get_element(0,1), 2, "Get right value 0,1");
_float($a->get_element(0,2), 3, "Get right value 0,2");
_float($a->get_element(0,3), 4, "Get right value 0,3");
_float($a->get_element(0,4), 5, "Get right value 0,4");
_float($a->get_element(0,5), 6, "Get right value 0,5");


$a = $m->slice( row => 0 );
_float($a->rows, 1, "Get right number of rows");
_float($a->columns, 6, "Get right number of cols");
_float($a->get_element(0,0), 1, "Get right value 0,0");
_float($a->get_element(0,1), 2, "Get right value 0,1");
_float($a->get_element(0,2), 3, "Get right value 0,2");
_float($a->get_element(0,3), 4, "Get right value 0,3");
_float($a->get_element(0,4), 5, "Get right value 0,4");
_float($a->get_element(0,5), 6, "Get right value 0,5");


$a = slice($m, row => 0);
_float($a->rows, 1, "Get right number of rows");
_float($a->columns, 6, "Get right number of cols");
_float($a->get_element(0,0), 1, "Get right value 0,0");
_float($a->get_element(0,1), 2, "Get right value 0,1");
_float($a->get_element(0,2), 3, "Get right value 0,2");
_float($a->get_element(0,3), 4, "Get right value 0,3");
_float($a->get_element(0,4), 5, "Get right value 0,4");
_float($a->get_element(0,5), 6, "Get right value 0,5");

## Get rows 1,2 and cols 2,3,4,5
my $b = $m->slice(row_range => [1,2], col_range => [2,5]);
_float($b->rows, 2, "Get right number of rows");
_float($b->columns, 4, "Get right number of cols");
_float($b->get_element(0,0), 9, "Get right value 0,0");
_float($b->get_element(0,1), 10, "Get right value 0,1");
_float($b->get_element(0,2), 11, "Get right value 0,2");
_float($b->get_element(0,3), 12, "Get right value 0,3");
_float($b->get_element(1,0), 15, "Get right value 1,0");
_float($b->get_element(1,1), 16, "Get right value 1,1");
_float($b->get_element(1,2), 17, "Get right value 1,2");
_float($b->get_element(1,3), 18, "Get right value 1,3");


## Get column 4    
my $c = $m->slice(col_range => [4,4]);
_float($c->rows, 3, "Get right number of rows");
_float($c->columns, 1, "Get right number of cols");
_float($c->get_element(0,0), 5, "Get right value 0,0");
_float($c->get_element(1,0), 11, "Get right value 0,1");
_float($c->get_element(2,0), 17, "Get right value 0,2");


$c = $m->slice( col => 4 );
_float($c->rows, 3, "Get right number of rows");
_float($c->columns, 1, "Get right number of cols");
_float($c->get_element(0,0), 5, "Get right value 0,0");
_float($c->get_element(1,0), 11, "Get right value 0,1");
_float($c->get_element(2,0), 17, "Get right value 0,2");


## Slice to column 2
my $d = $m->slice(col_range => [2,2]);
_float($d->rows, 3, "Get right number of rows");
_float($d->columns, 1, "Get right number of cols");
_float($d->get_element(0,0), 3, "Get right value 0,0");
_float($d->get_element(1,0), 9, "Get right value 0,1");
_float($d->get_element(2,0), 15, "Get right value 0,2");


$d = $m->slice(col => 2);
_float($d->rows, 3, "Get right number of rows");
_float($d->columns, 1, "Get right number of cols");
_float($d->get_element(0,0), 3, "Get right value 0,0");
_float($d->get_element(1,0), 9, "Get right value 0,1");
_float($d->get_element(2,0), 15, "Get right value 0,2");


done_testing;


sub _float {
  my ($a, $b, $c) = @_;
  is($a, float($b, tolerance => 0.000001), $c);
}



