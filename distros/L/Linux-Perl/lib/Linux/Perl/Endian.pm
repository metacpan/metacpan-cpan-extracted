package Linux::Perl::Endian;

use strict;
use warnings;

use constant SYSTEM_IS_BIG_ENDIAN => pack("S", 1) eq pack("n", 1);

1;
