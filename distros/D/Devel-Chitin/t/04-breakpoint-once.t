use strict;
use warnings;

use Test2::V0; no warnings 'void';
use lib 't/lib';
use TestHelper qw (ok_set_breakpoint ok_location db_continue);

# Since debugging isn't enabled until 'use TestHelper',
# this file's lines don't show up in the _<$filename, and we can't set
# breakpoints that get honored.  Starting a new compilation unit with
# use gets around that problem.
use SampleCode;

$DB::single=1;
SampleCode::looper();

sub __tests__ {
    plan tests => 4;

    my $file = 't/lib/SampleCode.pm';
    ok_set_breakpoint line => 13, file => $file, once => 1, 'Set "once" breakpoint within loop';
    ok_set_breakpoint line => 15, file => $file, 'Set breakpoint after loop';

    db_continue;
    ok_location line => 13, filename => $file;

    db_continue;
    ok_location line => 15, filename => $file;
}

