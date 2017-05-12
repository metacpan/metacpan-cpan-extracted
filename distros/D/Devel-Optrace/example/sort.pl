#!perl -w
use strict;

use Devel::Optrace -all;

my @a = (1, 3, 2, 6, 5);
@a = sort { $b <=> $a } @a;
