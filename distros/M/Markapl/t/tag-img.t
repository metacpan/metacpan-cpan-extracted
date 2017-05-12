#!/usr/bin/env perl -w
use strict;

package View;
use Markapl;

template zero => sub {
    img;
};

template one => sub {
    img(src => "/one.jpg");
};

template two => sub {
    img(src => "/two.jpg") {};
};

package main;
use Test::More tests => 3;

is(View->render("zero"), qq{<img>});
is(View->render("one"), qq{<img src="/one.jpg">});
is(View->render("two"), qq{<img src="/two.jpg">});


