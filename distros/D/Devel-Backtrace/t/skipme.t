#!/usr/bin/perl
use strict;
use warnings;
use Devel::Backtrace;
use Test::More tests => 8;

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

        warn "pure backtrace: $backtrace" if $ENV{DEBUG};

        # Tell Devel::Backtrace that we are not interested in what Baz method
        # calls which Baz method.
        $backtrace->skipme;

        warn "backtrace: $backtrace" if $ENV{DEBUG};

        use Test::More;

        is(scalar($backtrace->points), 5, 'skipme count')
            or warn "skipme count: $backtrace";
        is($backtrace->point(0)->subroutine, 'Baz::baz1', 'skipme')
            or warn "skipme: $backtrace";

        my $backtrace2 = Devel::Backtrace->new;

        # Tell Devel::Backtrace that we are not even interested where the first
        # Baz method was called.
        $backtrace2->skipmysubs;

        is (scalar($backtrace2->points), 4, 'skipmysubs count')
            or warn "skipmysubs count: $backtrace";
        is ($backtrace2->point(0)->subroutine, 'Bar::bar2', 'skipmysubs')
            or warn "skipmysubs: $backtrace";

        warn "backtrace2: $backtrace2" if $ENV{DEBUG};

        my $backtrace3 = Devel::Backtrace->new(1);
        $backtrace3->skipmysubs('Baz');

        warn "backtrace3: $backtrace3" if $ENV{DEBUG};

        is ($backtrace3->point(1)->to_string(-format => '%I'), 1, '%I')
            or warn "%I: $backtrace3";
        is ($backtrace3->point(1)->_skip, 4, '_skip')
            or warn "_skip: $backtrace3";
        is ($backtrace3->point(1)->to_string(-format => '%i'), 5, '%i')
            or warn "%i: $backtrace3";

        # Same as above, but use -start instead of plain argument to new.
        my $backtrace4 = Devel::Backtrace->new(-start => 1);
        $backtrace4->skipmysubs('Baz');
        is ($backtrace4->point(1)->_skip, 4, '_skip / -start')
            or warn "_skip / -start: $backtrace3 --\n$backtrace4";
    }
}
