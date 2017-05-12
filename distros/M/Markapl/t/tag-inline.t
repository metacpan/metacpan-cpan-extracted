#!/usr/bin/env perl -w
use strict;

package View;
use Markapl;

template vhr => sub {
    hr;
};

template vbr => sub {
    br;
};

template vimg => sub {
    img(src => "/one.jpg");
};

template vmeta => sub {
    meta(content => "text/html", "http-equiv" => "content-type");
};

template vhtml_link => sub {
    html_link(rel=>'stylesheet', href=>'/style.css');
};

template vinput => sub {
    input(type => "text", name => "foo");
};

package main;
use Test::More tests => 6;

is(View->render("vhr"), qq{<hr>});
is(View->render("vbr"), qq{<br>});
is(View->render("vimg"), qq{<img src="/one.jpg">});
is(View->render("vmeta"), qq{<meta content="text/html" http-equiv="content-type">});
is(View->render("vhtml_link"), qq{<link rel="stylesheet" href="/style.css">});
is(View->render("vinput"), qq{<input type="text" name="foo">});
