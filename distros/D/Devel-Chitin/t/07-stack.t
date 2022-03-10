use strict;
use warnings;

use Test2::V0;  no warnings 'void';
use lib 't/lib';
use TestHelper qw(do_test has_callsite);

foo(1,2,3);                 # line 8: void context
sub foo {
    my @a = Bar::bar();     # line 10: list context
}
sub Bar::bar {
    &Bar::baz;              # line 13: list
}
package Bar;
sub baz {
    my $a = eval {          # line 17: scalar
        eval "quux()";      # line 18: scalar
    };
}
sub AUTOLOAD {
    $DB::single=1;
    23;                     # scalar
}

package main;
use List::Util 1.45 'uniq';

sub __tests__ {
    plan tests => 13;

    do_test {
        my $loc = shift;

        my $filename = __FILE__;
        my $expected_callsite = has_callsite() ? T() : DNE();
        my $stack = TestHelper->stack;
        ok($stack, 'Get execution stack');

        my $expected_stack = array {
            item hash {
                field package    => 'Bar';
                field filename   => __FILE__;
                field line       => 23;
                field hasargs    => T();
                field wantarray  => DF();
                field evaltext   => U();
                field evalfile   => U();
                field evalline   => U();
                field is_require => U();
                field autoload   => 'quux';
                field subname    => 'AUTOLOAD';
                field args       => [];
                field serial     => T();

                field bitmask    => T();
                field callsite   => $expected_callsite;
                field hints      => T();
                field level      => 6;
                field subroutine => 'Bar::AUTOLOAD';
            };
            item hash {
                field package    => 'Bar';
                field filename   => match(qr/\(eval \d+\)\[\Q$filename\E:18\]/);
                field line       => 1;  # line 1 of the eval text
                field subroutine => '(eval)';
                field hasargs    => DF();
                field wantarray  => DF();
                field evaltext   => $^V lt v5.18 ? "quux()\n;" : 'quux()';
                field evalfile   => __FILE__;
                field evalline   => 18;
                field is_require => DF();
                field autoload   => U();
                field subname    => '(eval)';
                field args       => U();
                field serial     => T();
                field bitmask    => T();
                field callsite   => $expected_callsite;
                field hints      => T();
                field level      => 7;
            };
            item hash {
                field package    => 'Bar';
                field filename   => __FILE__;
                field line       => 18;
                field subroutine => '(eval)';
                field hasargs    => DF();
                field wantarray  => DF();
                field evaltext   => U();
                field evalfile   => U();
                field evalline   => U();
                field is_require => U();
                field autoload   => U();
                field subname    => '(eval)';
                field args       => U();
                field serial     => T();
                field bitmask    => T();
                field callsite   => $expected_callsite;
                field hints      => T();
                field level      => 8;
            };
            item hash {
                field package    => 'Bar';
                field filename   => __FILE__;
                field line       => 17;
                field subroutine => 'Bar::baz';
                field hasargs    => DF();  # Because it's called as &Bar::baz
                field wantarray  => T();
                field evaltext   => U();
                field evalfile   => U();
                field evalline   => U();
                field is_require => U();
                field autoload   => U();
                field subname    => 'baz';
                field args       => [];
                field serial     => T();
                field bitmask    => T();
                field callsite   => $expected_callsite;
                field hints      => T();
                field level      => 9;
            };
            item hash {
                field package    => 'main';
                field filename   => __FILE__;
                field line       => 13;
                field subroutine => 'Bar::bar';
                field hasargs    => T();
                field wantarray  => T();
                field evaltext   => U();
                field evalfile   => U();
                field evalline   => U();
                field is_require => U();
                field autoload   => U();
                field subname    => 'bar';
                field args       => [];
                field serial     => T();
                field bitmask    => T();
                field callsite   => $expected_callsite;
                field hints      => T();
                field level      => 10;
            };
            item hash {
                field package    => 'main';
                field filename   => __FILE__;
                field line       => 10;
                field subroutine => 'main::foo';
                field hasargs    => T();
                field wantarray  => U();
                field evaltext   => U();
                field evalfile   => U();
                field evalline   => U();
                field is_require => U();
                field autoload   => U();
                field subname    => 'foo';
                field args       => [1,2,3];
                field serial     => T();
                field bitmask    => T();
                field callsite   => $expected_callsite;
                field hints      => T();
                field level      => 11;
            };
            item hash {
                field package    => 'main';
                field filename   => __FILE__;
                field line       => 8;
                field subroutine => 'main::MAIN';
                field hasargs    => T();
                field wantarray  => U();
                field evaltext   => U();
                field evalfile   => U();
                field evalline   => U();
                field is_require => U();
                field autoload   => U();
                field subname    => 'MAIN';
                field args       => [];
                field serial     => T();
                field bitmask    => T();
                field callsite   => FDNE();
                field hints      => D();
                field level      => 12;
            };
            end();
        };
        is($stack, $expected_stack, 'stack contents');

        my(@serials, @callsites);
        for(my $framenum = 0; my $frame = $stack->frame($framenum); $framenum++) {
            push @serials, $frame->serial;
            push @callsites, $frame->callsite;
        }
        is( scalar(@serials), scalar(uniq @serials), 'frame serials are unique', @serials);
        is( scalar(@callsites), scalar(uniq @callsites), 'frame callsites are unique', @callsites);

        my $iter = $stack->iterator;
        ok($iter, 'Stack iterator');
        my @iter_serial;
        for(my $framenum = 0; my $frame = $iter->(); $framenum++) {
            is($frame, $stack->[$framenum], "Stack iterator frame $framenum");
        }

        # Get the stack again, serials should be the same
        Devel::Chitin::Stack::invalidate();  # force it to re-create it
        my $stack2 = TestHelper->stack();
        is($stack2, $stack, 'Stack is the same the second time');
    };
}
