use warnings;
use strict;

do "t/setup_pp.pl" or die $@ || $!;
do "t/version_feature.t" or die $@ || $!;

1;
