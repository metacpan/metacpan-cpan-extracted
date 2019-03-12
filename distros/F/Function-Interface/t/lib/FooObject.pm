package FooObject;
use Function::Interface::Impl qw(IFoo);
use Function::Parameters;
use Function::Return;

fun foo() :Return() { }

fun new($class) { bless {} => $class };

1;
