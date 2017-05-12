# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Math-SparseMatrix.t'

#########################

use Test::More tests => 45;

require_ok('Math::SparseVector');
BEGIN { use_ok('Math::SparseMatrix') };
require_ok('Math::SparseMatrix');

#########################

#########################
# creation

$spmatrix = Math::SparseMatrix->new(5, 10);
isa_ok($spmatrix, 'Math::SparseMatrix');

#########################
# get / set 

$spmatrix->set(5, 4, 25);
cmp_ok($spmatrix->get(5, 4), '==', 25, 'test get/set');

#########################
# saving to file / reading back

$spmatrix1 = Math::SparseMatrix->new(5, 4);
$spmatrix1->set(1,2,3);
$spmatrix1->set(2,3,5);
$spmatrix1->set(3,1,1);
$spmatrix1->set(4,4,7);
$spmatrix1->set(5,3,25);
$spmatrix1->writeToFile("test.mat");
$spmatrix2 = Math::SparseMatrix->createFromFile("test.mat");
for ($i = 1; $i < 6; $i++) {
    for ($j = 1; $j < 5; $j++) {
        cmp_ok($spmatrix1->get($i,$j), '==',$spmatrix2->get($i,$j), 'test saving and reading back from file');
    }
}

#########################
# reading transpose

$spmatrix3 = Math::SparseMatrix->new(4, 5);
$spmatrix3->set(1,3,1);
$spmatrix3->set(2,1,3);
$spmatrix3->set(3,2,5);
$spmatrix3->set(3,5,25);
$spmatrix3->set(4,4,7);
$spmatrix4 = Math::SparseMatrix->createTransposeFromFile("test.mat");
for ($i = 1; $i < 5; $i++) {
    for ($j = 1; $j < 6; $j++) {
        cmp_ok($spmatrix3->get($i,$j), '==', $spmatrix4->get($i,$j), 'test saving and reading back from file');
    }
}

unlink("test.mat");

