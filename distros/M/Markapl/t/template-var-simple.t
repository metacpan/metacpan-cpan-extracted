#!/usr/bin/env perl -w
use strict;

package View;
use Markapl;

template 'one' => sub {
    my ($self, %vars) = @_;
    h1(".title") { outs $vars{'title'} }
};

package main;
use Test::More tests => 1;

# View->set("title" => "foo");
my $out = View->render("one", title => "foo");
is $out, '<h1 class="title">foo</h1>';

