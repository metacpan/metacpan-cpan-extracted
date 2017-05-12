package Foobar;

use warnings;
use strict;

use Devel::Unwind;

sub unwind {
    unwind FOO;
}

1;
