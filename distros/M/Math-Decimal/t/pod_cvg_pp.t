use warnings;
use strict;

do "t/setup_pp.pl" or die $@ || $!;
do "t/pod_cvg.t" or die $@ || $!;

1;
