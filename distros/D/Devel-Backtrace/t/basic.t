#!perl
use strict;
use warnings;
use Test::More tests => 7;

use Devel::Backtrace;

my ($line0, $line1, $line2);

sub foo {
    $line1 = __LINE__; bar();
}

sub bar {
    $line2 = __LINE__; my $backtrace1 = Devel::Backtrace->new;
    my $backtrace1_str = "$backtrace1";
    $backtrace1_str =~ tr#\\#/#;
    is ($backtrace1_str, qq{Devel::Backtrace::new called from main (t/basic.t:$line2)
main::bar called from main (t/basic.t:$line1)
main::foo called from main (t/basic.t:$line0)\n}, 'stringification');

    my $backtrace2 = Devel::Backtrace->new(1);
    $backtrace2 =~ tr#\\#/#;
    is ("$backtrace2", qq{main::bar called from main (t/basic.t:$line1)
main::foo called from main (t/basic.t:$line0)\n}, 'stringification with argument 1 to new');

    my $backtrace3 = Devel::Backtrace->new(2);
    my $backtrace3_str = "$backtrace3";
    $backtrace3_str =~ tr#\\#/#;
    is($backtrace3_str, qq{main::foo called from main (t/basic.t:$line0)\n}, 'stringification with argument 2 to new');

    like($backtrace3->to_long_string, qr{^
package:\s*main\n
filename:\s*t[\\/]basic\.t\n
line:\s*\Q$line0\E\n
subroutine:\s*main::foo\n
hasargs:\s*1\n
wantarray:\s*undef\n
evaltext:\s*undef\n
is_require:\s*undef\n
hints:.*\n
bitmask:.*\n
\z}x, 'to_long_string');

    is ($backtrace1->point(1)->line, $line1, 'line number');

    is( $backtrace1->point(0)->called_package, 'Devel::Backtrace', 'called_package');

    my $backtrace4 = Devel::Backtrace->new(-start => 1,
        -format => 'subroutine %s, package %c from %p');
    is($backtrace4->point(0).'', 'subroutine main::bar, package main from main', 'format strings');
}

$line0 = __LINE__; foo();
