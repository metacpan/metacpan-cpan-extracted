use Test::More 'no_plan';
use warnings;
use strict;

package Foo::Bar;
use Gapp::Moose;

package main;
use Test::More;

my $o = Foo::Bar->new;
ok $o, 'created object instance';
isa_ok $o, 'Foo::Bar', 'isa Foo::Bar';



1;
