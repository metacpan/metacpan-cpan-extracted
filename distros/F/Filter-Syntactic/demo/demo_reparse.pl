#! /usr/bin/env perl

use 5.022;
use warnings;

use lib './demo/lib';
use Reparse;
use Test::More;

>-{     ok 1, 'unnested block';  }-<

>-{
        ok 2, 'pre nested block';

    >-{ ok 3, 'in nested block'; }-<

        ok 4, 'post nested block';

    >-{ ok 5, 'in another nested block'; }-<

        ok 6, 'post another nested block';

# Uncommenting the following code breaks the syntax
# because Reparse.pm replaces (rather than extending)
# the standard "old-style" Block syntax)...
#
#      { ok 6, 'old-style nested block'; }

}-<

done_testing();
