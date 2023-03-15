use warnings;
use strict;

do "./t/setup_pp.pl" or die $@ || $!;
do "./t/utf8_heavy.t" or die $@ || $!;

1;
