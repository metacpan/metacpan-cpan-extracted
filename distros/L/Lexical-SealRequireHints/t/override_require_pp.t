use warnings;
use strict;

do "./t/setup_pp.pl" or die $@ || $!;
do "./t/override_require.t" or die $@ || $!;

1;
