#!/usr/bin/perl

use lib "t/lib";
use strict;
use warnings;

use Test::More tests => 4;

use B qw(svref_2object);
use JSPL;
use DummyClass;

my $rt = JSPL::Runtime->new();

{
    my $sv;
    {
        my $cx = $rt->create_context();
        $cx->bind_class(name => "DummyClass");
    
        my $o = DummyClass->new;
        $sv = svref_2object($o);
        is($sv->REFCNT, 1, "RC 1");
    
        $cx->eval("function foo_global(obj) { ref = obj }");
        $cx->call(foo_global => $o);
        is($sv->REFCNT, 2, "RC 2");

        $cx->eval("function foo_local(obj) { var ref = obj }");
        $cx->call(foo_local => $o);
        is($sv->REFCNT, 2, "RC 2 again");
    }
    
    is($sv->REFCNT, 0);
}
