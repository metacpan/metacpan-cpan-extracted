#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 45;

my ($x, $nrow, $ncol);
my (@nrow, @ncol, @nelm, @npag, @ndim);

note('$x = Math::Matrix -> new([[1,2,3],[4,5,6]]);');

$x = Math::Matrix -> new([[1,2,3],[4,5,6]]);
($nrow, $ncol) = $x -> size();
cmp_ok($nrow, '==', 2, 'Number of rows in 2-by-3 matrix');
cmp_ok($ncol, '==', 3, 'Number of columns in 2-by-3 matrix');

@nrow = $x -> nrow();
cmp_ok(scalar(@nrow), '==', 1, 'Number of elements returned by nrow()');
cmp_ok($nrow[0], '==', 2, 'Value returned by nrow()');

@ncol = $x -> ncol();
cmp_ok(scalar(@ncol), '==', 1, 'Number of elements returned by ncol()');
cmp_ok($ncol[0], '==', 3, 'Value returned by ncol()');

@nelm = $x -> nelm();
cmp_ok(scalar(@nelm), '==', 1, 'Number of elements returned by nelm()');
cmp_ok($nelm[0], '==', 6, 'Value returned by nelm()');

@npag = $x -> npag();
cmp_ok(scalar(@npag), '==', 1, 'Number of elements returned by npag()');
cmp_ok($npag[0], '==', 1, 'Value returned by npag()');

@ndim = $x -> ndim();
cmp_ok(scalar(@ndim), '==', 1, 'Number of elements returned by ndim()');
cmp_ok($ndim[0], '==', 2, 'Value returned by ndim()');

note('$nrow = $x -> nrow();');

cmp_ok($x -> nrow(), '==', 2, 'Number of rows in 2-by-3 matrix');
cmp_ok($x -> ncol(), '==', 3, 'Number of columns in 2-by-3 matrix');
cmp_ok($x -> nelm(), '==', 6, 'Number of elements in 2-by-3 matrix');
cmp_ok($x -> npag(), '==', 1, 'Number of pages in 2-by-3 matrix');
cmp_ok($x -> ndim(), '==', 2, 'Number of dimensions in 2-by-3 matrix');

note('$x = Math::Matrix -> new([[1,2,3]]);');

$x = Math::Matrix -> new([[1,2,3]]);
($nrow, $ncol) = $x -> size();
cmp_ok($nrow, '==', 1, 'Number of rows in 1-by-3 matrix');
cmp_ok($ncol, '==', 3, 'Number of columns in 1-by-3 matrix');

cmp_ok($x -> nrow(), '==', 1, 'Number of rows in 1-by-3 matrix');
cmp_ok($x -> ncol(), '==', 3, 'Number of columns in 1-by-3 matrix');
cmp_ok($x -> nelm(), '==', 3, 'Number of elements in 1-by-3 matrix');
cmp_ok($x -> npag(), '==', 1, 'Number of pages in 1-by-3 matrix');
cmp_ok($x -> ndim(), '==', 1, 'Number of dimensions in 1-by-3 matrix');

note('$x = Math::Matrix -> new([[1],[2],[3]]);');

$x = Math::Matrix -> new([[1],[2],[3]]);
($nrow, $ncol) = $x -> size();
cmp_ok($nrow, '==', 3, 'Number of rows in 3-by-1 matrix');
cmp_ok($ncol, '==', 1, 'Number of columns in 3-by-1 matrix');

cmp_ok($x -> nrow(), '==', 3, 'Number of rows in 3-by-1 matrix');
cmp_ok($x -> ncol(), '==', 1, 'Number of columns in 3-by-1 matrix');
cmp_ok($x -> nelm(), '==', 3, 'Number of elements in 3-by-1 matrix');
cmp_ok($x -> npag(), '==', 1, 'Number of pages in 3-by-1 matrix');
cmp_ok($x -> ndim(), '==', 1, 'Number of dimensions in 3-by-1 matrix');

note('$x = Math::Matrix -> new([[3]]);');

$x = Math::Matrix -> new([[3]]);
($nrow, $ncol) = $x -> size();
cmp_ok($nrow, '==', 1, 'Number of rows in 1-by-1 matrix');
cmp_ok($ncol, '==', 1, 'Number of columns in 1-by-1 matrix');

cmp_ok($x -> nrow(), '==', 1, 'Number of rows in 1-by-1 matrix');
cmp_ok($x -> ncol(), '==', 1, 'Number of columns in 1-by-1 matrix');
cmp_ok($x -> nelm(), '==', 1, 'Number of elements in 1-by-1 matrix');
cmp_ok($x -> npag(), '==', 1, 'Number of pages in 1-by-1 matrix');
cmp_ok($x -> ndim(), '==', 0, 'Number of dimensions in 1-by-1 matrix');

note('$x = Math::Matrix -> new([]);');

$x = Math::Matrix -> new([]);
($nrow, $ncol) = $x -> size();
cmp_ok($nrow, '==', 0, 'Number of rows in empty matrix');
cmp_ok($ncol, '==', 0, 'Number of columns in empty matrix');

cmp_ok($x -> nrow(), '==', 0, 'Number of rows in empty matrix');
cmp_ok($x -> ncol(), '==', 0, 'Number of columns in empty matrix');
cmp_ok($x -> nelm(), '==', 0, 'Number of elements in empty matrix');
cmp_ok($x -> npag(), '==', 0, 'Number of pages in empty matrix');
cmp_ok($x -> ndim(), '==', 2, 'Number of dimensions in empty matrix');
