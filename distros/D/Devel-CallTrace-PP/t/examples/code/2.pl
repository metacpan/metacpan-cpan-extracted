package Foo;

sub bar {
    baz();
}

sub baz {
    1;
}

package trunk;

Foo::bar();
