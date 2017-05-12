#!/usr/bin/env perl -w
use strict;

package View;
use Markapl;

template one => sub {
    h1 { outs "A < B" }
};

template two => sub {
    h1 { outs_raw "<em>A</em>" }
};

package main;
use Test::More tests => 2;

is(View->render("one"), "<h1>A &lt; B</h1>");
is(View->render("two"), "<h1><em>A</em></h1>")

