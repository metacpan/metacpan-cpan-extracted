#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;
use Goto::Cached;

sub test {
    my $val = '';

    goto LABEL2;

    LABEL1:
    $val .= 1;
    goto LABEL3;

    LABEL2:
    $val .= 2;
    goto LABEL1;

    LABEL3:
    $val .= 3;
    return $val;
}

{
    goto LABEL1;

    fail('not reached');

    LABEL1:
    goto LABEL2;

    fail('not reached');
}

fail('not reached');

LABEL2: ok(1);

is(test(), '213');
is(test(), '213');
