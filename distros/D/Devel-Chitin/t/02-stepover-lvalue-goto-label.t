use strict;
use warnings;

use Test2::V0;  no warnings 'void';
use lib 't/lib';
use TestHelper qw(ok_location db_stepover);

do_goto() = 1;
GOTO_TARGET:
10;
my $x;
sub do_goto : lvalue {
    $DB::single = 1;
    goto GOTO_TARGET; # line 14
    $x;
}

sub __tests__ {
    plan tests => 2;

    ok_location subroutine => 'main::do_goto', line => 14;
    db_stepover;
    ok_location line => 9;
}
