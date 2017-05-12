#!/usr/bin/env perl

use lib 't/lib';
use Test::More tests => 1;
use MyTestView;

my $out = MyTestView->render("/undef-attribute-value.html");
is(
    $out,
    '<script async src="foo.js"></script>',
    "async attribute renders correctly"
);
