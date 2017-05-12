#!/usr/bin/env perl

# use YAML;
# {no strict; *{p} = sub { print YAML::Dump(@_) }}

use Markapl;
package MyView;

use Markapl;

sub simple {
    h1 { "Hi" };
    h2 (class => "title") { "Hello World" };
}

sub simple2 {
    h1("#title") { "cc" };
}

no Markapl;
package main;
use Test::More tests => 2;

is(MyView->render("simple"),
   q{<h1>Hi</h1><h2 class="title">Hello World</h2>},
   "It renders h1 and h2(class => \"title\")");

is(MyView->render("simple2"),
   q{<h1 id="title">cc</h1>},
   "It renders h1#title");

# require Devel::Symdump;
# my $obj = Devel::Symdump->new("main", "MyView");
# print YAML::Dump([$obj->functions]);
