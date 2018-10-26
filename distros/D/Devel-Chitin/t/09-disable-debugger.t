use strict;
use warnings;

use Test2::V0; no warnings 'void';
use lib 't/lib';
use TestHelper qw(db_trace db_step db_disable ok_set_breakpoint do_test do_disable_auto_disable);
use SampleCode;

$DB::single=1;  # needed to get the tests defined in __test__ to run
SampleCode::foo();
$DB::single=1;
11;

sub __tests__ {
    plan tests => 2;

    # Turn on several mechanisms to stop the debugger, then disable it
    # If we ever get stopped, the TestHelper will complain there are no more
    # tests remaining and fail the test
    db_trace(1);
    ok_set_breakpoint file => 't/lib/SampleCode.pm', line => 5, 'Set breakpoint that will be skipped';
    do_disable_auto_disable;
    db_disable;
    db_step;
}

END {
    pass('Ran to the end');
}
