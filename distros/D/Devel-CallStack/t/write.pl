sub foo1 { Devel::CallStack::write() }
sub foo2 { }
foo1();
rename("callstack.out", "tmp.out");
foo2();
rename("tmp.out", "callstack.out");
