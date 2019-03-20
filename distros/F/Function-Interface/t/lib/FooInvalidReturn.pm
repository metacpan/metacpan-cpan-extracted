package FooInvalidReturn;
use Function::Interface::Impl qw(IFoo);

use Types::Standard -types;

fun foo() :Return(Str) {}

1;
