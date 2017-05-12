#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';

use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;

run_test(
    4,
    sub {
        eval {
            $DB::single = 1;
            do_die(); # line 14
        };
        wrap_die(); # line 16
        17;
        sub wrap_die {
            eval {
                $DB::single=1; # line 20
                do_die();
            }
        }
        sub do_die {
            die "in do_die";
        }
    },
    loc(line => 14, subroutine => '(eval)'),
    'stepover',
    loc(line => 16),

    'continue',
    loc(line => 21, subroutine => '(eval)'),
    'stepover',
    loc(line => 17),
    'done'
);
