#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';

use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;

run_test(
    6,
    sub { $DB::single=1;
        my $a = 1;
        13;
        $a = 2;
        15;
        $a = 3;
        17;
        18;
        19;
    },
    \&create_breakpoints,
    'continue',
    loc(line => 15),
    'continue',
    'at_end',
    'done',
);
    

sub create_breakpoints {
    my($db, $loc) = @_;
    Test::More::ok(Devel::Chitin::Breakpoint->new(
            file => $loc->filename,
            line => 13,
            code => '$a == 2',
        ), 'Set conditional breakpoint on line 13');
    Test::More::ok(Devel::Chitin::Breakpoint->new(
            file => $loc->filename,
            line => 15,
            code => '$a == 2',
        ), 'Set conditional breakpoint that will fire on line 15');
    Test::More::ok(Devel::Chitin::Breakpoint->new(
            file => $loc->filename,
            line => 17,
            code => '$a == 2',
        ), 'Set conditional breakpoint on line 17');
    Test::More::ok(Devel::Chitin::Breakpoint->new(
            file => $loc->filename,
            line => 10,
            code => 0,
        ), 'Set breakpoint that will never fire on line 17');
}

