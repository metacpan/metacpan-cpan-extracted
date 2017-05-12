#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 6;
use Goto::Cached;

sub test {
    my $label = shift;

    goto $label;

    LABEL1:
    is($label, 'LABEL1');
    return;

    LABEL2:
    is($label, 'LABEL2');
    return;

    LABEL3:
    is($label, 'LABEL3');
    return;
}

test('LABEL1');
test('LABEL2');
test('LABEL3');

test('LABEL3');
test('LABEL2');
test('LABEL1');
