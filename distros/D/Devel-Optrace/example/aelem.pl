#!perl -w
use strict;

use Devel::Optrace -all;


my @a;
$a[1]++;
$a[1000]++;

our @b;
$b[1]++;
$b[1000]++;
