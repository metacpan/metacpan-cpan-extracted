package lexical1;

use strict;
use warnings;

# try to contaminate lexical2
# this should not happen if Lexical::SealRequireHints is installed

BEGIN {
    $^H |= 0x20000;
    $^H{'Devel::Pragma::Leak'} = 1
}

use lexical2;

sub test { lexical2::test() }

1;
