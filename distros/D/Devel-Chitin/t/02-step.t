use strict;
use warnings; no warnings 'void';

use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;

run_test(
    5,
    sub {
        $DB::single=1;
        12;
        foo();
        14;
        sub foo {
            16;
        }
    },
    loc(line => 12),
    'step',
    loc(line => 13),
    'step',
    loc(subroutine => 'main::foo', line => 16),
    'step',
    loc(line => 14),
    'step',
    'at_end',
);


