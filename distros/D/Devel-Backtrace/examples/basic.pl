#!perl
use strict;
use warnings;

use Devel::Backtrace;

sub foo {
    bar();
}

sub bar {
    my $backtrace1 = Devel::Backtrace->new;
    print "First backtrace:\n$backtrace1\n";

    my $backtrace2 = Devel::Backtrace->new(1);
    print "Second (shorter) backtrace:\n$backtrace2\n";

    my $backtrace3 = Devel::Backtrace->new(2);
    print "Third (even shorter) backtrace:\n$backtrace3\n";

    print "The third backtrace in a very long form:\n";
    print "(Note that the bitmask may depend on the perl version.)\n";
    print $backtrace3->to_long_string, "\n";

    print "The line number from the second line of the first backtrace:\n";
    print $backtrace1->point(1)->line, "\n";

    print "The called package from the first line of the first backtrace:\n";
    print $backtrace1->point(0)->called_package, "\n";

    my $backtrace4 = Devel::Backtrace->new(-start => 1,
        -format => 'subroutine %s, package %c from %p');
    print "bar call in different format:\n";
    print $backtrace4->point(0);
}


foo();

__END__

Output:

First backtrace:
Devel::Backtrace::new called from main (examples/basic.pl:12)
main::bar called from main (examples/basic.pl:8)
main::foo called from main (examples/basic.pl:38)

Second (shorter) backtrace:
main::bar called from main (examples/basic.pl:8)
main::foo called from main (examples/basic.pl:38)

Third (even shorter) backtrace:
main::foo called from main (examples/basic.pl:38)

The third backtrace in a very long form:
(Note that the bitmask may depend on the perl version.)
package: main
filename: examples/basic.pl
line: 38
subroutine: main::foo
hasargs: 1
wantarray: undef
evaltext: undef
is_require: undef
hints: 2
bitmask: UUUUUUUUUUUU\05

The line number from the second line of the first backtrace:
8

The called package from the first line of the first backtrace:
Devel::Backtrace

bar call in different format:
subroutine main::bar, package main from main
