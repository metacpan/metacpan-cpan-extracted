#!perl -w
use strict;
use 5.010;

use Devel::Optrace -all;

foreach my $i(reverse 1, 2){
	say $i;
}

foreach (10){
	say;
}
