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
        13;
        sub do_goto {
            $DB::single = 1;
            goto \&goto_target; # line 16
        }
        sub goto_target {
            19;
        }
    },
    loc(subroutine => 'main::do_goto', line => 16),
    'stepover',
    loc(subroutine => 'main::goto_target', line => 19),
    'done'
);
