#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Fun;

fun Foo::foo ($x, $y) {
    $x + $y;
}

ok(!main->can('foo'));
ok(Foo->can('foo'));
is(Foo::foo(1, 2), 3);

done_testing;
