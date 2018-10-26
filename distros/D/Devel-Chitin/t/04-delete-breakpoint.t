use strict;
use warnings;

use Test2::V0; no warnings 'void';
use lib 't/lib';
use TestHelper qw(ok_location ok_set_breakpoint ok_delete_breakpoint db_continue);
use SampleCode;

$DB::single=1;
SampleCode::foo();
SampleCode::foo();
$DB::single=1;
13;

sub __tests__ {
    plan tests => 4;

    my $file = 't/lib/SampleCode.pm';
    ok_set_breakpoint file => $file, line => 5, 'Set breakpoint';

    db_continue;
    ok_location filename => $file, line => 5;

    ok_delete_breakpoint file => $file, line => 5, 'Delete breakpoint';

    db_continue;
    ok_location filename => __FILE__, line => 13;
}

