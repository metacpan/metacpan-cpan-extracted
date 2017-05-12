#!/usr/bin/env perl -w

use strict;
use Test::More tests => 1;

package View;
use Markapl;

template 'foo' => sub {
    my ($self, %args) = @_;
    outs $args{title};
};

package main;

my $out = View->render('foo', title => "Hi");
is($out, "Hi");


