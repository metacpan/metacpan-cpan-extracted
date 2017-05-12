use warnings;
use strict;

do "t/setup_pp.pl" or die $@ || $!;
do "t/version_check.t" or die $@ || $!;

1;
