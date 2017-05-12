#!/usr/bin/env perl -w
use strict;
use Test::More tests => 1;

package View;
use Markapl;

template one => sub {
    h1 { "Hello Everyone" }
    p { "Merry Xmas" }
};

package main;

my $out = View->render("one");
# diag $out;
like($out, qr{<h1>.+?</h1><p>.+?</p>})
