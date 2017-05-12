my %C;
sub foo1 { %C = Devel::CallStack::get() }
sub foo2 { }
foo1();
foo2();
Devel::CallStack::set(%C)
