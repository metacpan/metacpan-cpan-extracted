#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';

use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;

run_test(
    6,
    sub {
        one();
        sub one {
            $DB::single=1;
            15;
        }
        two(); # 17
        sub subtwo {
            $DB::single=1;
            20;
        }
        sub two {
            subtwo();
            24;
        }
        three();  # 26
        sub three {
            $DB::single=1;
            29;
            three_three();
            31;
        }
        sub three_three {
            34;
        }
        36;
    },
    loc(subroutine => 'main::one', line => 15),
    'stepout',
    loc(line => 17),
    'continue',
    'stepout',
    loc(subroutine => 'main::two', line => 24),
    'stepout',
    loc(line => 26),
    'continue',
    loc(subroutine => 'main::three', line => 29),
    'stepout',
    loc(line => 36),
    'done'
);
