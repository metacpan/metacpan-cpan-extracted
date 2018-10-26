use strict;
use warnings;

use Test2::V0; no warnings 'void';
use lib 't/lib';
use TestHelper qw(ok_location ok_breakable ok_not_breakable ok_set_breakpoint ok_breakpoint
                  do_test db_continue);

# Since debugging isn't enabled until 'use TestHelper',
# this file's lines don't show up in the _<$filename, and we can't set
# breakpoints that get honored.  Starting a new compilation unit with
# use gets around that problem.
use SampleCode;

$DB::single=1;
SampleCode::foo();

sub __tests__ {  # 15
    plan tests => 20;

    my $file = 't/lib/SampleCode.pm';
    do_test {
        ok ! Devel::Chitin::Breakpoint->new(file => 'garbage_file_name', line => 1, code => 1),
            q(Can't create breakpoint in non-existent file);
        ok ! Devel::Chitin::Breakpoint->new(file => $file, line => 99, code => 1),
            q(Can't create breakpoint on non-existent line');
        ok ! Devel::Chitin::Breakpoint->new(file => $file, line => 1, code => 1),
            q(Can't create breakpoint on non-breakable line);
    };

    ok_breakable $file, 5;
    ok_not_breakable $file, 4;
    ok_not_breakable $file, 10;

    ok_set_breakpoint line => 5, file => $file, 'Set unconditional breakpoint';
    ok_set_breakpoint line => 6, code => 0, file => $file, 'Set conditional breakpoint that will not fire';
    ok_set_breakpoint line => 7, code => 1, inactive => 1,  file => $file, 'Set unconditional, inactive breakpoint';
    ok_set_breakpoint line => 8, code => 0, file => $file, 'Set another conditional breakpoint that will not fire';
    ok_set_breakpoint line => 8, file => $file, 'Set unconditional on that same line';

    do_test {
        my @got_bp = Devel::Chitin::Breakpoint->get(file => $file);
        is(scalar(@got_bp), 5, 'got all expected breakpoints');

        foreach my $test ( [ 5 => 1 ], [ 6 => 1 ], [ 7 => 1 ], [ 8 => 2 ] ) {
            my($line, $expected_bp) = @$test;
            @got_bp = Devel::Chitin::Breakpoint->get(file => $file, line => $line);
            is(scalar(@got_bp), $expected_bp, "expected breakpoint count for line $line");
        }

        foreach my $code ( 0, 1 ) {
            @got_bp = Devel::Chitin::Breakpoint->get(file => $file, line => 8, code => $code);
            is( scalar(@got_bp), 1, "Got one breakpoint on line 12 with code $code");
        }
    };

    db_continue;

    ok_location line => 5, filename => $file;

    db_continue;
    ok_location line => 8, filename => $file;
};

