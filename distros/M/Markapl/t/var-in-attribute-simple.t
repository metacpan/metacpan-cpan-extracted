#!/usr/bin/env perl -w
use strict;

package View;
use Markapl;

template 'one' => sub {
    h1 { "one" }
};

template 'two' => sub {
    h1(class => "title") { "two" };
};

template 'three' => sub {
    my $title = "three";
    h1(class => $title) { "three" };
};

template 'four' => sub {
    h1(class => "id-four") { "four" };
};

package main;
use Test::More tests => 4;


{
    my $out = View->render("four");
    is $out, qq{<h1 class="id-four">four</h1>};
}

{
    my $out = View->render("three");
    is $out, qq{<h1 class="three">three</h1>};
}

{
    my $out = View->render("two");
    is $out, qq{<h1 class="title">two</h1>};
}

{
    my $out = View->render("one");
    is($out, "<h1>one</h1>");
}
