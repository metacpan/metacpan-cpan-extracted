#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';

use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;

run_test(
    2,
    sub {
        do_goto();
        GOTO_TARGET:
        14; # actually 13
        sub do_goto {
            $DB::single = 1;
            goto GOTO_TARGET; # line 17
        }
    },
    loc(subroutine => 'main::do_goto', line => 17),
    'stepover',
    loc(line => 13),
    'done'
);
