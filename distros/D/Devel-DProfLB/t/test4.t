#!perl -d:DProfLB
# -*- perl -*-

sub foo {
    sleep 1;
    die {};
}

sub bar {
    sleep 1;
    foo();
    sleep 1;	# this never happens
}

sub baz {
    sleep 1;
    eval { bar() };
    sleep 1;	# because of the exception, this gets accounted for in foo
}

baz();

print "1..1\nok 1\n";
