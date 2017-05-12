#! /usr/bin/env perl

## 00-util.t --- test procedure for utility functions.

# Copyright (C) 2010 Ralph Schleicher.  All rights reserved.

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

## Code:

use strict;
use warnings;

use Test::Simple tests => 27;

BEGIN
{
  unshift (@INC, 'lib', '../lib');
}

use Math::MatrixDecomposition::Util qw(:all);

my ($re, $im);

ok (1 + eps   != 1, '1 + eps  ');
ok (1 + eps/2 == 1, '1 + eps/2');

ok (mod ( 0, 1) == 0, 'mod ( 0, 1)');
ok (mod (-2, 1) == 0, 'mod (-2, 1)');
ok (mod ( 2, 1) == 0, 'mod ( 2, 1)');
ok (mod (-3.14, 1) != 0, 'mod (-3.14, 1)');
ok (mod ( 3.14, 1) != 0, 'mod ( 3.14, 1)');

ok (min (3, 3) == 3, 'min (3, 3)');
ok (min (3, 5) == 3, 'min (3, 5)');
ok (min (5, 3) == 3, 'min (5, 3)');

ok (max (3, 3) == 3, 'max (3, 3)');
ok (max (3, 5) == 5, 'max (3, 5)');
ok (max (5, 3) == 5, 'max (5, 3)');

ok (sign (-2, -1) == -2, 'sign (-2, -1)');
ok (sign (-2,  0) ==  2, 'sign (-2,  0)');
ok (sign (-2,  1) ==  2, 'sign (-2,  1)');
ok (sign ( 0, -1) ==  0, 'sign ( 0, -1)');
ok (sign ( 0,  0) ==  0, 'sign ( 0,  0)');
ok (sign ( 0,  1) ==  0, 'sign ( 0,  1)');
ok (sign ( 2, -1) == -2, 'sign ( 2, -1)');
ok (sign ( 2,  0) ==  2, 'sign ( 2,  0)');
ok (sign ( 2,  1) ==  2, 'sign ( 2,  1)');
ok (sign (eps/9, -1) == -(eps/9), 'sign (eps/9, -1)');
ok (sign (eps/9,  0) ==  (eps/9), 'sign (eps/9,  0)');
ok (sign (eps/9,  1) ==  (eps/9), 'sign (eps/9,  1)');

ok (hypot (3, 4) == 5, 'hypot (3, 4)');

($re, $im) = cdiv (4, -3, -2, 7);
ok ($re == -29/53 && $im == -22/53, 'cdiv (4, -3, -2, 7)');

## 00-util.t ends here
