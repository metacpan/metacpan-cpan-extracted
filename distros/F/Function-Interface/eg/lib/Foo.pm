package Foo;

use Function::Interface::Impl qw(IFoo);
use Types::Standard -types;

fun hello(Str $msg) :Return(Str) {
    return "HELLO $msg";
}

1;
