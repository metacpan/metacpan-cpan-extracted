#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);

local $| = 1;
sub foo {
    say 1;
}

foo();

__DATA__
# args: write

write(1, *, *) = * at write.pl line 9.
    main::foo() called at write.pl line 12
