
#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 18;

note('Math::Matrix -> randn(2, 3);');

{
    my $x = Math::Matrix -> randn(2, 3);
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    my ($nrow, $ncol) = $x -> size();
    cmp_ok($nrow, '==', 2, 'number of rows in $x');
    cmp_ok($ncol, '==', 3, 'number of columns in $x');
}

note('Math::Matrix -> randn(1, 3);');

{
    my $x = Math::Matrix -> randn(1, 3);
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    my ($nrow, $ncol) = $x -> size();
    cmp_ok($nrow, '==', 1, 'number of rows in $x');
    cmp_ok($ncol, '==', 3, 'number of columns in $x');
}

note('Math::Matrix -> randn(3, 1);');

{
    my $x = Math::Matrix -> randn(3, 1);
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    my ($nrow, $ncol) = $x -> size();
    cmp_ok($nrow, '==', 3, 'number of rows in $x');
    cmp_ok($ncol, '==', 1, 'number of columns in $x');
}

note('Math::Matrix -> randn(3);');

{
    my $x = Math::Matrix -> randn(3);
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    my ($nrow, $ncol) = $x -> size();
    cmp_ok($nrow, '==', 3, 'number of rows in $x');
    cmp_ok($ncol, '==', 3, 'number of columns in $x');
}

note('Math::Matrix -> randn(0);');

{
    my $x = Math::Matrix -> randn(0, 0);
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    my ($nrow, $ncol) = $x -> size();
    cmp_ok($nrow, '==', 0, 'number of rows in $x');
    cmp_ok($ncol, '==', 0, 'number of columns in $x');
}

note('Math::Matrix -> randn();');

{
    my $x = Math::Matrix -> randn();
    is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
    my ($nrow, $ncol) = $x -> size();
    cmp_ok($nrow, '==', 1, 'number of rows in $x');
    cmp_ok($ncol, '==', 1, 'number of columns in $x');
}
