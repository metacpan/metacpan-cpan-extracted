use strict;
use warnings;

use Test2::V0; no warnings 'void';
use lib 't/lib';
use TestHelper qw(ok_location ok_set_breakpoint db_continue_to db_continue);

# Since debugging isn't enabled until 'use TestHelper',
# this file's lines don't show up in the _<$filename, and we can't set
# breakpoints that get honored.  Starting a new compilation unit with
# use gets around that problem.
use SampleCode;

$DB::single=1;
14;
15;
SampleCode::looper();
SampleCode::foo();
19;
SampleCode::foo();
$DB::single=1;
22;

sub __tests__ {
    plan tests => 5;

    my $file = 't/lib/SampleCode.pm';

    ok_set_breakpoint line => 15, code => 1, file => $file, 'Set unconditional breakpoint';  # within looper()
    db_continue_to $file, 13;

    ok_location line => 13, filename => $file;
    db_continue_to 'SampleCode::foo';

    ok_location line => 15, filename => $file;  # This was the breakpoint we set
    db_continue;

    ok_location line => 5, filename => $file;   # This was the continue_to
    db_continue;

    ok_location line => 22, filename => __FILE__;
};

