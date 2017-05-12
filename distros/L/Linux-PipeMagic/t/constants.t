#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Linux::PipeMagic qw/ SPLICE_F_MOVE SPLICE_F_NONBLOCK SPLICE_F_MORE SPLICE_F_GIFT /;

# XXX - nasty test, assumes constants don't actually change.

is(eval("SPLICE_F_MOVE()"), 1) or diag $@;
is(eval("SPLICE_F_NONBLOCK()"), 2) or diag $@;
is(eval("SPLICE_F_MORE()"), 4) or diag $@;
is(eval("SPLICE_F_GIFT()"), 8) or diag $@;

done_testing();

