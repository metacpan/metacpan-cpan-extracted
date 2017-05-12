#!perl -w
use strict;
use Tie::Scalar;

use Devel::Optrace -all;

tie my($x), 'Tie::StdScalar';
$x++;
