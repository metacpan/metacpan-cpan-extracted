#!/usr/bin/env perl -w
use lib 't/lib';
use strict;
use Test::More tests => 1;

use MyTestView;

my $out = MyTestView->render("/perlbuiltin.html");

like(
    $out,
    qr/<q>(.+)<\/q>/,
    "q tag."
);
