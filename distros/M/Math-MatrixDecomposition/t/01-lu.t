#! /usr/bin/env perl

## 01-lu.t --- test procedure for LU decomposition.

# Copyright (C) 2010 Ralph Schleicher.  All rights reserved.

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

## Code:

use strict;
use warnings;

use Test::Simple tests => 13;

BEGIN
{
  unshift (@INC, 'lib', '../lib');
}

use Math::MatrixDecomposition::LU;

my $LU = Math::MatrixDecomposition::LU->new;

if (1)
  {
    my ($A, $b, $x);

    # Solve a system of linear equations.
    $A = [ -3, -1, 12,  2,
            0,  2,  2, -7,
           10,  1, -2,  3,
            2, -9,  1, -1];

    $b = [ 27,
           30,
          -10,
           27];

    $LU->decompose ($A);
    $x = $LU->solve ($b);

    ok ($$x[0] ==  1, '$$x[0] ==  1');
    ok ($$x[1] == -2, '$$x[1] == -2');
    ok ($$x[2] ==  3, '$$x[2] ==  3');
    ok ($$x[3] == -4, '$$x[3] == -4');
  }

if (1)
  {
    my $A;

    # Calculate the inverse matrix.
    $A = [1, 2, 0,
          2, 3, 0,
          3, 4, 1];

    $LU->decompose ($A);

    @$A = (1, 0, 0,
           0, 1, 0,
           0, 0, 1);

    $LU->solve ($A);

    ok ($$A[0] == -3, '$$A[0] == -3');
    ok ($$A[1] ==  2, '$$A[1] ==  2');
    ok ($$A[2] ==  0, '$$A[2] ==  0');
    ok ($$A[3] ==  2, '$$A[3] ==  2');
    ok ($$A[4] == -1, '$$A[4] == -1');
    ok ($$A[5] ==  0, '$$A[5] ==  0');
    ok ($$A[6] ==  1, '$$A[6] ==  1');
    ok ($$A[7] == -2, '$$A[7] == -2');
    ok ($$A[8] ==  1, '$$A[8] ==  1');
  }

## 01-lu.t ends here
