use strict;
use warnings;

use Test2::V0; no warnings 'void';
use lib 't/lib';
use TestHelper qw(db_trace db_continue ok_location ok_trace_location);

$DB::single=1;
9;
my $i = 0;
while ($i < 2) {
    foo();
} continue {
    $i++;
}
16;
sub foo {
    18;
}

sub __tests__ {
    plan tests => 10;

    db_trace(1);
    ok_location package => 'main', subroutine => 'MAIN', line => 9, filename => __FILE__;
    db_continue();

    ok_trace_location package => 'main', subroutine => 'MAIN', line => 10, filename => __FILE__;
    # for loop condition
    ok_trace_location package => 'main', subroutine => 'MAIN', line => 11, filename => __FILE__;
    # about to call foo()
    ok_trace_location package => 'main', subroutine => 'MAIN', line => 12, filename => __FILE__;
    ok_trace_location package => 'main', subroutine => 'main::foo', line => 18, filename => __FILE__;
    # continue
    ok_trace_location package => 'main', subroutine => 'MAIN', line => 14, filename => __FILE__;
    # about to call foo() again
    ok_trace_location package => 'main', subroutine => 'MAIN', line => 12, filename => __FILE__;
    ok_trace_location package => 'main', subroutine => 'main::foo', line => 18, filename => __FILE__;
    # continue
    ok_trace_location package => 'main', subroutine => 'MAIN', line => 14, filename => __FILE__;
    # done
    ok_trace_location package => 'main', subroutine => 'MAIN', line => 16, filename => __FILE__;
}

