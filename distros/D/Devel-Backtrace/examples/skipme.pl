#!/usr/bin/perl
use strict;
use warnings;
use Devel::Backtrace;

# This script demonstrates the use of the skipme method.

Foo::foo1();

{
    package Foo;

    sub foo1 {
        foo2();
    }

    sub foo2 {
        Bar::bar1();
    }
}

{
    package Bar;

    sub bar1 {
        bar2();
    }

    sub bar2 {
        Baz::baz1();
    }
}

{
    package Baz;

    sub baz1 {
        baz2();
    }

    sub baz2 {
        baz3();
    }

    sub baz3 {
        my $backtrace = Devel::Backtrace->new;

        # Tell Devel::Backtrace that we are not interested in what Baz method
        # calls which Baz method.
        $backtrace->skipme;

        print "skipme result:\n";
        print $backtrace;

        my $backtrace2 = Devel::Backtrace->new;

        # Tell Devel::Backtrace that we are not even interested where the first
        # Baz method was called.
        $backtrace2->skipmysubs;

        print "\nskipmycalls result:\n";
        print $backtrace2;
    }
}

__END__

Output:

skipme result:
Baz::baz1 called from Bar (examples/skipme.pl:30)
Bar::bar2 called from Bar (examples/skipme.pl:26)
Bar::bar1 called from Foo (examples/skipme.pl:18)
Foo::foo2 called from Foo (examples/skipme.pl:14)
Foo::foo1 called from main (examples/skipme.pl:8)

skipmycalls result:
Bar::bar2 called from Bar (examples/skipme.pl:26)
Bar::bar1 called from Foo (examples/skipme.pl:18)
Foo::foo2 called from Foo (examples/skipme.pl:14)
Foo::foo1 called from main (examples/skipme.pl:8)
