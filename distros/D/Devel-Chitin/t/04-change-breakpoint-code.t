#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';

use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;

run_test(
    5,
    sub {
        $a = 0;
        $DB::single=1; 13;
        foo();
        $a = 1; # 15
        foo();
        foo();
        sub foo {
            1;  # 19;
        }
        $DB::single=1;
        22;
    },
    \&set_breakpoints,
    'continue',
    loc(line => 19, subroutine => 'main::foo'),
    \&change_breakpoint,
    'continue',
    loc(line => 22),
    'done'
);

sub set_breakpoints {
    my($debugger, $loc) = @_;

    Test::More::ok(Devel::Chitin::Breakpoint->new(
            file => $loc->filename,
            line => 19,
            code => '$a',
        ), 'Set conditional breakpoint');
}

sub change_breakpoint {
    my($debugger, $loc) = @_;

    my($bp) = $debugger->get_breaks(file => $loc->filename, line => 19);
    Test::More::ok($bp, 'retrieved breakpoint');
    Test::More::is($bp->code('0'), '0', 'Change breakpoint condition to not fire');
}

