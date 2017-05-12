use warnings;
use strict;

do "t/setup_pp.pl" or die $@ || $!;
do "t/eval.t" or die $@ || $!;

1;
