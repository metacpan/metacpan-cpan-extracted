use strict;
use warnings;

use Test2::V0; no warnings 'void';
use lib 't/lib';
use TestHelper qw(ok_set_breakpoint ok_change_breakpoint ok_location db_continue);

# Since debugging isn't enabled until 'use TestHelper',
# this file's lines don't show up in the _<$filename, and we can't set
# breakpoints that get honored.  Starting a new compilation unit with
# use gets around that problem.
use SampleCode;

$DB::single=1;
SampleCode::foo();
SampleCode::foo();
SampleCode::foo();
$DB::single=1;
19;

sub __tests__ {
    plan tests => 4;

    my $file = 't/lib/SampleCode.pm';
    ok_set_breakpoint line => 5, file => $file, code => 1, 'Set unconditional breakpoint';

    db_continue;
    ok_location line => 5, filename => $file;
    ok_change_breakpoint line => 5, file => $file, change => { code => 0 }, 'Change previous breakpoint to not stop';

    db_continue;
    ok_location line => 19, filename => __FILE__;
}

