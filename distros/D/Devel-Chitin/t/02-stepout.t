use strict;
use warnings;

use Test2::V0; no warnings 'void';
use lib 't/lib';
use TestHelper qw(ok_location db_continue db_stepout);

one();
sub one {
    $DB::single=1;
    11;
}
two(); # 13
sub subtwo {
    $DB::single=1;
    16;
}
sub two {
    subtwo();
    20;
}
three();  # 22
sub three {
    $DB::single=1;
    25;
    three_three();
    27;
}
sub three_three {
    30;
}
32;

sub __tests__ {
    plan tests => 6;

    ok_location subroutine => 'main::one', line => 11;
    db_stepout;
    ok_location line => 13;
    db_continue;
    db_stepout;
    ok_location subroutine => 'main::two', line => 20;
    db_stepout;
    ok_location line => 22;
    db_continue;
    ok_location subroutine => 'main::three', line => 25;
    db_stepout;
    ok_location line => 32;
}
