use warnings;
use strict;

alarm 10;

use Lexical::SealRequireHints;
do "t/seal.t" or die $@ || $!;

1;
