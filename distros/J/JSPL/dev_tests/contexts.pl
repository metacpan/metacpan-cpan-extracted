#!/usr/bin/perl

use strict;
use warnings;

use Devel::Peek;
use JSPL;

my $rt = JSPL::Runtime->new();
my $cx1 = $rt->create_context();

$cx1->bind_class(name => "Foo",
                 constructor => sub {
                     my $pkg = shift;
                     is($pkg, "Foo");
                     return Foo->new();
                 }
             );
             
             Dump($cx1);
             
