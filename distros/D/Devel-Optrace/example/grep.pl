#!perl -w
use strict;
use Tie::Scalar;

use Devel::Optrace -all;


my @a = map { $_ * 10 } 1 .. 4;
