use strict;
use warnings;

use Test2::V0;  no warnings 'void';
use lib 't/lib';
use TestHelper qw(ok_location db_stepover);

do_goto();
9;
sub do_goto {
    $DB::single = 1;
    goto \&goto_target; # line 12
}
sub goto_target {
    15;
}

sub __tests__ {
    plan tests => 2;

    ok_location subroutine => 'main::do_goto', line => 12;
    db_stepover;
    ok_location subroutine => 'main::goto_target', line => 15;
}
