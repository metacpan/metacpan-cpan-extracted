use strict;
use warnings;

use Test2::V0;  no warnings 'void';
use lib 't/lib';
use TestHelper qw(ok_location db_stepover db_continue);

eval {
    $DB::single = 1;
    do_die(); # line 10
};
wrap_die(); # line 12
17;
sub wrap_die {
    eval {
        $DB::single=1; # line 16
        do_die();
    }
}
sub do_die {
    die "in do_die";
}


sub __tests__ {
    plan tests => 4;

    ok_location line => 10, subroutine => '(eval)';
    db_stepover;
    ok_location line => 12;
    db_continue;
    ok_location line =>  17, subroutine => '(eval)';
    db_stepover;
    ok_location line => 13;
}
