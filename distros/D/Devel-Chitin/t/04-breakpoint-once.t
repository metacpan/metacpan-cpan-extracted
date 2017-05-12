#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';

use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;

run_test(
    3,
    sub {
        $DB::single=1; 12;
        for(my $i = 0; $i < 10; $i++) {
            14;
        }
    },
    \&create_once_breakpoint,
    'continue',
    loc(line => 14),
    'continue',
    'at_end',
    'done',
);

sub create_once_breakpoint {
    my($tester, $loc) = @_;
    Test::More::ok(Devel::Chitin::Breakpoint->new(
            file => $loc->filename,
            line => 14,
            once => 1,
        ), 'Set one-time, unconditional breakpoint on line 14');
}

