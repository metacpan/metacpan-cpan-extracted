#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;
use Goto::Cached;

sub test {
    my $val = '';

    goto LABEL2;

    return $val;

    LABEL1: $val .= '1';
    goto LABEL3;

    LABEL2: $val .= '2';
    goto LABEL1;

    LABEL3: $val .= '3';
    return $val;
}

is(test(), '213');
is(test(), '213');
is(test(), '213');
