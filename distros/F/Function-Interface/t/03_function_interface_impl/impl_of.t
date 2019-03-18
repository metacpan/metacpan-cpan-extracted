use Test2::V0;
use lib 't/lib';

CHECK { 
    note "THIRD";
    my $foo = bless {}, 'Foo';
    ok Function::Interface::Impl::impl_of('Foo', 'IFoo');
    ok Function::Interface::Impl::impl_of($foo, 'IFoo');
};

use Function::Interface::Impl;

BEGIN {
    note "FIRST";
    my $foo = bless {}, 'Foo';
    ok not Function::Interface::Impl::impl_of('Foo', 'IFoo');
    ok not Function::Interface::Impl::impl_of($foo, 'IFoo');
};

package Foo;
use Function::Interface::Impl qw(IFoo);
use Function::Parameters;
use Function::Return;

fun foo() :Return() {}

package main;

BEGIN { 
    note "SECOND";
    my $foo = bless {}, 'Foo';
    ok not Function::Interface::Impl::impl_of('Foo', 'IFoo');
    ok not Function::Interface::Impl::impl_of($foo, 'IFoo');
};

done_testing;
