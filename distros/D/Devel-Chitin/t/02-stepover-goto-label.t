use strict;
use warnings;

use Test2::V0;  no warnings 'void';
use lib 't/lib';
use TestHelper qw(ok_location db_stepover);

do_goto();
GOTO_TARGET:
10;
sub do_goto {
    $DB::single = 1;
    goto GOTO_TARGET; # line 13
}

sub __tests__ {
    plan tests => 2;

    ok_location subroutine => 'main::do_goto', line => 13;
    db_stepover;
    ok_location line => 9;
}
