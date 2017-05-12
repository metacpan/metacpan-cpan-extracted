sub foo1 { Devel::CallStack::set() }
sub foo2 { }
foo1();
foo2();
